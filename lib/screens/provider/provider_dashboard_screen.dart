import 'package:flutter/foundation.dart'; // Added for kIsWeb check
import '../../utils/image_url_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../models/booking.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../auth/login_screen.dart';
import 'create_product_screen.dart';
import 'create_package_screen.dart';
import '../shared/chat_screen.dart'; 
import '../shared/booking_detail_screen.dart'; 

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

Widget _buildProviderChatTile(BuildContext context, Booking booking, String clientName, int clientId, int creativeUserId) {
  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            providerName: clientName,
            clientId: clientId,
            creativeUserId: creativeUserId,
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.indigo.shade50,
            child: Text(
              clientName.isNotEmpty ? clientName[0].toUpperCase() : "?",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Tap to view messages",
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    ),
  );
}


class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  int _selectedIndex = 0; // 0: Home, 1: Bookings, 2: Orders, 3: Inbox, 4: Profile
  
  // Data Futures
  late Future<List<Booking>> _futureBookings;
  late Future<List<Booking>> _futureAllBookings;
  late Future<List<Order>> _futureOrders;
  late Future<List<Product>> _futureProducts;
  late Future<List<Map<String, dynamic>>> _futurePackages;
  late Future<Map<String, dynamic>> _futureReports;

  // State variable to track message count for Badge
  int _unreadMsgCount = 0;

  // GlobalKey for inventory section
  final GlobalKey _inventoryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  /// Returns the current user's ID (the creative/provider)
  Future<int?> _getCreativeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }


  void _refreshData() {
    setState(() {
      // All bookings (for Bookings tab and Inbox)
      _futureAllBookings = ApiService.fetchMyBookings();

      // Only confirmed bookings (for Overview stat card)
      _futureBookings = _futureAllBookings
          .then((list) => list.where((b) => b.status == 'confirmed').toList());

      _futureOrders = ApiService.fetchProviderOrders();
      _futureProducts = _fetchProductsChain();
      _futurePackages = _fetchPackagesChain();
      _futureReports = ApiService.fetchProviderReports();

      // Update badge count based on ALL bookings (pending + confirmed)
      _futureAllBookings.then((bookings) {
        if (mounted) {
          setState(() {
            _unreadMsgCount = bookings.length;
          });
        }
      }).catchError((e) {
        debugPrint("Error loading booking count: $e");
      });
    });
  }

  Future<List<Product>> _fetchProductsChain() async {
    try {
      final int? id = await ApiService.getMyCreativeId();
      if (id != null) {
        return await ApiService.fetchProducts(id);
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchPackagesChain() async {
    try {
      final int? id = await ApiService.getMyCreativeId();
      if (id != null) {
        return await ApiService.fetchServicePackages(id);
      }
    } catch (e) {
      debugPrint("Error fetching packages: $e");
    }
    return [];
  }

  // LOGIC: Calculate Total Earnings from Orders
  double _calculateTotalEarnings(List<Order> orders) {
    double total = 0.0;
    for (var order in orders) {
      // Only count orders that are NOT cancelled
      if (order.status.toLowerCase() != 'cancelled') {
        total += order.totalPrice;
      }
    }
    return total;
  }



  Future<void> _updateStatus(int id, String status) async {
    bool success = await ApiService.updateBookingStatus(id, status);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Booking ${status.toUpperCase()}"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: status == 'confirmed' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      );
      _refreshData();
    }
  }

  // Update Order Status
  Future<void> _updateOrderStatus(int id, String status) async {
    try {
        bool success = await ApiService.updateOrderStatus(id, status);
        
        if (success) {
          String msg = status == 'shipped' ? "Order Marked as Shipped" : "Order Declined";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              behavior: SnackBarBehavior.floating,
              backgroundColor: status == 'shipped' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          );
          _refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to update order status"), backgroundColor: Colors.red),
          );
        }
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ApiService.updateOrderStatus not found or failed. $e"), backgroundColor: Colors.red),
        );
    }
  }

  Future<void> _deleteProduct(Product product) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Product", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete '${product.name}'?", style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await ApiService.deleteProduct(product.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Product deleted successfully"), backgroundColor: Colors.green),
          );
          _refreshData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to delete product"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deletePackage(Map<String, dynamic> package) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Package", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete '${package['title']}'?", style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await ApiService.deleteServicePackage(package['id']);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Package deleted successfully"), backgroundColor: Colors.green),
          );
          _refreshData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to delete package"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _logout() async {
    await ApiService.logout();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed': return const Color(0xFF059669);
      case 'cancelled': return const Color(0xFFDC2626);
      case 'completed': return const Color(0xFF2563EB);
      default: return const Color(0xFFD97706);
    }
  }

  Color _getStatusBgColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed': return const Color(0xFFD1FAE5);
      case 'cancelled': return const Color(0xFFFEE2E2);
      case 'completed': return const Color(0xFFDBEAFE);
      default: return const Color(0xFFFEF3C7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          _getTitle(_selectedIndex),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
        ),
        backgroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),

      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),      // Index 0
          _buildBookingsTab(),  // Index 1
          _buildOrdersTab(),    // Index 2
          _buildInboxTab(),     // Index 3
          _buildProfileTab(),   // Index 4
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: BottomNavigationBar(
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
            const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Bookings'),
            const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: 'Orders'),
            
            // Badge to Inbox Icon
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: _unreadMsgCount > 0,
                label: Text(_unreadMsgCount > 99 ? '99+' : '$_unreadMsgCount'),
                backgroundColor: Colors.red,
                child: const Icon(Icons.chat_bubble_rounded),
              ),
              label: 'Inbox',
            ),

            const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF4F46E5),
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 12),
          elevation: 0,
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? _buildFabMenu()
          : null,
    );
  }

  Widget _buildFabMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'product') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateProductScreen()),
          ).then((_) => _refreshData());
        } else if (value == 'package') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePackageScreen()),
          ).then((_) => _refreshData());
        }
      },
      offset: const Offset(0, -120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 8,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'product',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory_2_rounded, color: Colors.blue.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              Text("New Product", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'package',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.design_services_rounded, color: Colors.purple.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              Text("New Package", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
      child: FloatingActionButton.extended(
        onPressed: null, // Handled by PopupMenuButton
        label: Text("Create", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 4,
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0: return "Dashboard";
      case 1: return "My Bookings";
      case 2: return "Order Management";
      case 3: return "Messages";
      case 4: return "My Profile";
      default: return "";
    }
  }

  // --- TAB 1: HOME (Overview) ---
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // 1. REAL EARNINGS CARD
            FutureBuilder<List<Order>>(
              future: _futureOrders,
              builder: (context, snapshot) {
                double earnings = 0.0;
                if (snapshot.hasData) {
                  earnings = _calculateTotalEarnings(snapshot.data!);
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF4338CA)], // Purple Gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Total Balance", style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Text(
                                "₱${earnings.toStringAsFixed(2)}", // Real Calculated Value
                                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FutureBuilder<Map<String, dynamic>>(
                        future: _futureReports,
                        builder: (context, reportSnap) {
                          final rate = reportSnap.hasData ? (reportSnap.data!['conversion_rate'] ?? 0).toDouble() : 0.0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(rate > 50 ? Icons.trending_up : Icons.trending_flat, color: Colors.greenAccent, size: 16),
                                const SizedBox(width: 4),
                                Text("${rate.toStringAsFixed(1)}% conversion", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // 2. Statistics Grid
            Row(
  children: [
    Expanded(
      child: _buildStatCard(
        title: "Active Bookings",
        icon: Icons.calendar_today_rounded,
        future: _futureBookings, // already filtered to confirmed
        color: Colors.orange,
        onTap: () {
          setState(() => _selectedIndex = 1);   // Go to BOOKINGS tab
        },
      ),
    ),
    const SizedBox(width: 16),
    Expanded(
      child: _buildStatCard(
        title: "Total Products",
        icon: Icons.inventory_2_rounded,
        future: _futureProducts,
        color: Colors.blue,
        onTap: () {
          // Scroll down to inventory OR go to product management page
          Scrollable.ensureVisible(
            _inventoryKey.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        },
      ),
    ),
  ],
),



            const SizedBox(height: 16),
            
            // NEW: Orders Stat Card
            FutureBuilder<List<Order>>(
              future: _futureOrders,
              builder: (context, snapshot) {
                String count = snapshot.hasData ? "${snapshot.data!.length}" : "-";
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.shopping_bag_rounded, color: Colors.green.shade600, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(count, style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                          Text("Total Orders", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // 3. Inventory Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Inventory", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                TextButton(
                  onPressed: () {}, 
                  child: Text("See All", style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 4. Products Grid
            FutureBuilder<List<Product>>(
              future: _futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text("No products in inventory", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text("Start selling by adding your first product.", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 12)),
                      ],
                    ),
                  );
                }

                // Grid View Builder
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 items per row
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75, // Adjust height of cards
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => _buildProductGridCard(snapshot.data![index]),
                );
              },
            ),
            const SizedBox(height: 32),

            // 5. My Packages Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("My Packages", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreatePackageScreen()),
                    ).then((_) => _refreshData());
                  },
                  child: Text("+ Add", style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5))),
                ),
              ],
            ),
            const SizedBox(height: 12),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _futurePackages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.design_services_outlined, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text("No service packages yet", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text("Create packages so clients can book your services.", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 12)),
                      ],
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.map((pkg) => _buildPackageCard(pkg)).toList(),
                );
              },
            ),
            const SizedBox(height: 32),

            // 6. Reports Section
            _buildReportsSection(),

            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
  required String title,
  required IconData icon,
  required Future<List<dynamic>> future,
  required MaterialColor color,
  required VoidCallback onTap,
}) {
  return FutureBuilder<List<dynamic>>(
    future: future,
    builder: (context, snapshot) {
      String count = snapshot.hasData ? "${snapshot.data!.length}" : "-";

      return InkWell(
        onTap: snapshot.hasData ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color.shade600, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                count,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  // Grid Card for Products
  Widget _buildProductGridCard(Product product) {
    // Check if URL is valid
    bool hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              clipBehavior: Clip.hardEdge,
              child: hasImage
                  ? Image.network(
                      fixImageUrl(product.imageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40);
                      },
                    )
                  : Icon(Icons.image_outlined, color: Colors.grey[400], size: 40),
            ),
          ),
          
          // Details Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold, 
                    fontSize: 14, 
                    color: const Color(0xFF111827)
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "₱${product.price.toStringAsFixed(2)}",
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF4F46E5), 
                    fontWeight: FontWeight.bold, 
                    fontSize: 14
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: product.stock > 0 ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.stock > 0 ? "Stock: ${product.stock}" : "No Stock",
                        style: GoogleFonts.plusJakartaSans(
                          color: product.stock > 0 ? Colors.green.shade700 : Colors.red.shade700, 
                          fontSize: 10, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CreateProductScreen(existingProduct: product)),
                            ).then((_) => _refreshData());
                          }, // Edit action
                          child: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => _deleteProduct(product), // Delete action
                          child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Package Card
  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  pkg['title'] ?? 'Untitled Package',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CreatePackageScreen(existingPackage: pkg),
                        ),
                      ).then((_) => _refreshData());
                    },
                    child: const Icon(Icons.edit_outlined,
                        size: 20, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => _deletePackage(pkg),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pkg['description'] ?? '',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.grey.shade600, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "₱${double.parse(pkg['price'].toString()).toStringAsFixed(2)}",
                  style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF4F46E5),
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    pkg['delivery_time'] ?? '',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // REPORTS SECTION
  // =========================================================================
  Widget _buildReportsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _futureReports,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
          );
        }

        final data = snapshot.data ?? {};
        if (data.isEmpty) return const SizedBox.shrink();

        final bookingRevenue = (data['booking_revenue'] ?? 0).toDouble();
        final productRevenue = (data['product_revenue'] ?? 0).toDouble();
        final conversionRate = (data['conversion_rate'] ?? 0).toDouble();
        final monthlyTrend = List<Map<String, dynamic>>.from(data['monthly_trend'] ?? []);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Reports", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
            const SizedBox(height: 16),

            // Mini cards row
            Row(
              children: [
                Expanded(child: _buildMiniReportCard("Booking\nRevenue", "₱${bookingRevenue.toStringAsFixed(0)}", Icons.calendar_today_rounded, const Color(0xFF4F46E5))),
                const SizedBox(width: 10),
                Expanded(child: _buildMiniReportCard("Product\nRevenue", "₱${productRevenue.toStringAsFixed(0)}", Icons.shopping_bag_rounded, const Color(0xFF10B981))),
                const SizedBox(width: 10),
                Expanded(child: _buildMiniReportCard("Conversion\nRate", "${conversionRate.toStringAsFixed(1)}%", Icons.trending_up_rounded, const Color(0xFFF59E0B))),
              ],
            ),

            const SizedBox(height: 24),

            // Monthly Earnings Chart
            Text("Monthly Earnings", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
            const SizedBox(height: 4),
            Text("Last 6 months", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 16),

            Container(
              height: 200,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: _buildLineChart(monthlyTrend),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniReportCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
          const SizedBox(height: 2),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> trend) {
    if (trend.isEmpty) return const SizedBox.shrink();

    final maxRevenue = trend.map((t) => (t['revenue'] ?? 0).toDouble()).reduce((a, b) => a > b ? a : b);
    final maxY = maxRevenue > 0 ? maxRevenue * 1.3 : 1000.0;

    final spots = trend.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value['revenue'] ?? 0).toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF4F46E5),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: const Color(0xFF4F46E5),
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF4F46E5).withOpacity(0.08),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= trend.length) return const SizedBox.shrink();
                final month = trend[idx]['month'] ?? '';
                final parts = month.split('-');
                final label = parts.length == 2 ? _monthLabel(int.tryParse(parts[1]) ?? 0) : '';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '₱${spot.y.toStringAsFixed(0)}',
                  GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  String _monthLabel(int month) {
    const labels = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return month >= 1 && month <= 12 ? labels[month] : '';
  }

  // --- TAB 2: BOOKINGS (Clickable) ---
  Widget _buildBookingsTab() {
    return FutureBuilder<List<Booking>>(
      future: _futureAllBookings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState("No booking requests");

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final booking = snapshot.data![index];
            return GestureDetector(
              onTap: () {
                // Navigate to details with isProvider: true
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BookingDetailScreen(
                        booking: booking, 
                        isProvider: true // <--- IMPORTANT: This flips the UI to Provider mode
                    )
                )).then((_) => _refreshData());
              },
              child: _buildBookingCard(booking)
            );
          },
        );
      },
    );
  }

  // --- TAB 3: ORDERS ---
  Widget _buildOrdersTab() {
    return FutureBuilder<List<Order>>(
      future: _futureOrders,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState("No orders received yet");

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildOrderCard(snapshot.data![index]),
        );
      },
    );
  }

  // --- TAB 4: INBOX (Functional & Clickable) ---
   Widget _buildInboxTab() {
  return SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ---------------- HEADER ----------------
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Messages",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                decoration: InputDecoration(
                  hintText: "Search conversations...",
                  hintStyle: GoogleFonts.plusJakartaSans(
                      color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Colors.grey.shade400, size: 20),
                  filled: true,
                  fillColor: Color(0xFFF3F4F6),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),

        // ---------------- CONVERSATION LIST ----------------
        Expanded(
          child: FutureBuilder<List<Booking>>(
            future: _futureAllBookings,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        "No Messages",
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Client messages will appear here",
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              final bookings = snapshot.data!;

              // De-duplicate by clientId: one chat per client
              final Map<int, Booking> uniqueClients = {};
              for (final b in bookings) {
                final cId = b.clientId ?? 0;
                uniqueClients.putIfAbsent(cId, () => b);
              }
              final uniqueChats = uniqueClients.values.toList();

              return FutureBuilder<int?>(
                future: _getCreativeUserId(),
                builder: (context, userSnap) {
                  final creativeUserId = userSnap.data ?? 0;

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: uniqueChats.length,
                    itemBuilder: (context, index) {
                      final booking = uniqueChats[index];
                      final clientId = booking.clientId ?? 0;

                      final clientName = (booking.clientName != null &&
                              booking.clientName!.isNotEmpty)
                          ? booking.clientName!
                          : "Client #${booking.id}";

                      return _buildProviderChatTile(
                        context, booking, clientName, clientId, creativeUserId,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
  }

   // --- TAB 5: PROFILE ---
 Widget _buildProfileTab() {
  return SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),

          // --- PROFILE AVATAR ---
          CircleAvatar(
            radius: 45,
            backgroundColor: const Color(0xFFEEF2FF),
            child: const Icon(Icons.person_rounded, size: 50, color: Color(0xFF4F46E5)),
          ),

          const SizedBox(height: 16),

          // --- PROFILE TITLE ---
          Text(
            "My Profile",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 24),

          // =====================================
          //  MENU ITEMS
          // =====================================

          // --- EDIT PROFILE ---
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: Color(0xFF4F46E5)),
            title: Text("Edit Profile", style: GoogleFonts.plusJakartaSans()),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {},
          ),

          // --- ACCOUNT SETTINGS ---
          ListTile(
            leading: const Icon(Icons.settings_rounded, color: Color(0xFF4F46E5)),
            title: Text("Account Settings", style: GoogleFonts.plusJakartaSans()),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {},
          ),

          // --- HELP & SUPPORT ---
          ListTile(
            leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF4F46E5)),
            title: Text("Help & Support", style: GoogleFonts.plusJakartaSans()),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {},
          ),

          const SizedBox(height: 60),

          // =====================================
          //  LOGOUT BUTTON (matching client style)
          // =====================================
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.logout_rounded),
                label: Text(
                  "Log Out",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  // --- WIDGET HELPERS ---

  Widget _buildEmptyState(String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade200),
      const SizedBox(height: 16),
      Text(message, style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
    ]));
  }

  Widget _buildBookingCard(Booking booking) {
    bool isPending = booking.status == 'pending';
    bool isConfirmed = booking.status == 'confirmed'; 

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.calendar_today_rounded, size: 20, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Booking #${booking.id}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Web Design Service", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _getStatusBgColor(booking.status), borderRadius: BorderRadius.circular(20)),
            child: Text((booking.status ?? 'Pending').toUpperCase(), style: GoogleFonts.plusJakartaSans(color: _getStatusColor(booking.status), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
          child: Text(
            booking.requirements, 
            style: GoogleFonts.plusJakartaSans(color: Colors.grey[700], fontSize: 14), 
            maxLines: 2, 
            overflow: TextOverflow.ellipsis
          ),
        ),
        const SizedBox(height: 16),
        
        // ACTIONS (Redirect to Detail Screen)
        if (isPending || isConfirmed) 
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BookingDetailScreen(
                        booking: booking, 
                        isProvider: true
                    )
                )).then((_) => _refreshData()); // Refresh after back
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPending ? const Color(0xFF4F46E5) : Colors.white,
                foregroundColor: isPending ? Colors.white : const Color(0xFF4F46E5),
                side: isPending ? BorderSide.none : const BorderSide(color: Color(0xFF4F46E5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Text(isPending ? "Review Request" : "View Details"),
            ),
          ),
      ]),
    );
  }

  // Order Card with Buttons
  Widget _buildOrderCard(Order order) {
    bool isPending = order.status == 'pending'; 

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.local_mall_outlined, color: Colors.indigo.shade600, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.productName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF111827))),
              const SizedBox(height: 4),
              Text("Client: ${order.clientName}", style: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 13)),
            ])),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("₱${order.totalPrice}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF4F46E5))),
                Text("Qty: ${order.quantity}", style: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 12)),
              ],
            )
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Status", style: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.orange.shade400, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(order.status.toUpperCase(), style: GoogleFonts.plusJakartaSans(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          
          // Buttons for Pending Orders
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateOrderStatus(order.id, 'cancelled'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Decline"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateOrderStatus(order.id, 'shipped'), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Accept"),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}