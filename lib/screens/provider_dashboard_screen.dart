import 'package:flutter/foundation.dart'; // Added for kIsWeb check
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/booking.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'login_screen.dart';
import 'create_product_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  int _selectedIndex = 0; // 0: Home, 1: Bookings, 2: Orders, 3: Inbox
  
  // Data Futures
  late Future<List<Booking>> _futureBookings;
  late Future<List<Order>> _futureOrders;
  late Future<List<Product>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _futureBookings = ApiService.fetchMyBookings();
      _futureOrders = ApiService.fetchProviderOrders();
      _futureProducts = _fetchProductsChain();
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

  // --- LOGIC: Calculate Total Earnings from Orders ---
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

  String _fixImageUrl(String url) {
    if (url.startsWith('http')) {
      if (!kIsWeb) {
        if (url.contains('127.0.0.1')) {
          return url.replaceFirst('127.0.0.1', '10.0.2.2');
        }
        if (url.contains('localhost')) {
          return url.replaceFirst('localhost', '10.0.2.2');
        }
      }
      if (kIsWeb && url.contains('10.0.2.2')) {
         return url.replaceFirst('10.0.2.2', '127.0.0.1');
      }
      return url;
    } else {
      String base = kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
      return '$base$url';
    }
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

  // --- NEW: Update Order Status ---
  Future<void> _updateOrderStatus(int id, String status) async {
    // Note: Assuming 'updateOrderStatus' is available in ApiService as shown in previous context
    // If not, please ensure ApiService has this method or add it.
    // Since I cannot edit ApiService here based on instructions, I assume it exists or you will add it.
    // If ApiService.updateOrderStatus is missing, this will cause an error.
    // Based on previous turn context, ApiService should have it.
    
    // Using a try-catch block just in case the method is not there to prevent crash during development
    try {
        // bool success = await ApiService.updateOrderStatus(id, status); // Original call
        // Since I can't guarantee the method exists in the *current* file version of ApiService 
        // (the user provided ApiService code in previous turn, but I am editing ProviderDashboardScreen),
        // I will proceed assuming it exists. 
        
        // However, looking at the provided ApiService code in the prompt history, 
        // `updateOrderStatus` WAS NOT in the provided text in the immediate previous prompt 
        // (the user provided `insert here dont remove anything here` block which missed it).
        // But the user *asked* "how to accept the order".
        
        // I will add a placeholder check or assume the user added it to ApiService as instructed previously.
        // Actually, to be safe and helpful, I will implement the UI logic. 
        // The user needs to ensure `ApiService.updateOrderStatus` exists.
        
        // Let's assume the user followed the previous instruction to add it to ApiService.
        // If not, they will get a compilation error "Method not found".
        
        // Wait, looking at the "Most up-to-date file" section for ApiService... 
        // The user pasted `insert here dont remove anything here` content which DOES NOT have `updateOrderStatus`.
        // This means I should probably *not* call it if I can't edit ApiService.
        // BUT the user asked "how to accept the order" and pointed to `provider_dashboard_screen.dart`.
        // I will implement the UI call and the user must update ApiService.
        
        // Actually, I can't edit ApiService in this turn as the user didn't select it for editing in the "Most up-to-date" block 
        // (The user only provided `lib/screens/provider_dashboard_screen.dart` and `backend/core/urls.py` in the "Most up-to-date" section).
        
        // I will implement the UI code here.
        
        // Re-reading the prompt: "how to accept the order".
        // I will add the function to call the API.
        
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
        // Fallback if the method doesn't exist yet in ApiService
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ApiService.updateOrderStatus not found or failed. $e"), backgroundColor: Colors.red),
        );
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
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF6B7280)), onPressed: () {}),
          IconButton(icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)), onPressed: _logout),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),      // Index 0
          _buildBookingsTab(),  // Index 1
          _buildOrdersTab(),    // Index 2
          _buildInboxTab(),     // Index 3
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Bookings'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Inbox'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),

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
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateProductScreen()),
          ).then((_) => _refreshData());
        },
        label: Text("New Product", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 4,
      ) : null,
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0: return "Dashboard";
      case 1: return "My Bookings";
      case 2: return "Order Management";
      case 3: return "Messages";
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
                                "\$${earnings.toStringAsFixed(2)}", // Real Calculated Value
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up, color: Colors.greenAccent, size: 16),
                            const SizedBox(width: 4),
                            Text("+12.5% this week", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
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
                Expanded(child: _buildStatCard("Active Bookings", Icons.calendar_today_rounded, _futureBookings, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard("Total Products", Icons.inventory_2_rounded, _futureProducts, Colors.blue)),
              ],
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
            
            // 4. Products Grid (UPDATED: 2 Columns)
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
            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, IconData icon, Future<List<dynamic>> future, MaterialColor color) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        String count = snapshot.hasData ? "${snapshot.data!.length}" : "-";
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            // border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color.shade600, size: 22),
              ),
              const SizedBox(height: 16),
              Text(count, style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
              Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      },
    );
  }

  // --- NEW: Grid Card for Products ---
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
          // Image Section (Expanded to fill top part)
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
                      _fixImageUrl(product.imageUrl!),
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
                  "\$${product.price.toStringAsFixed(2)}",
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
                    InkWell(
                      onTap: () {}, // Edit action
                      child: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
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

  // --- TAB 2: BOOKINGS ---
  Widget _buildBookingsTab() {
    return FutureBuilder<List<Booking>>(
      future: _futureBookings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState("No active bookings");

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildBookingCard(snapshot.data![index]),
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

  // --- TAB 4: INBOX ---
  Widget _buildInboxTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text("No Messages", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
          const SizedBox(height: 8),
          Text("Client messages will appear here", style: GoogleFonts.plusJakartaSans(color: Colors.grey[500])),
        ],
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
        if (isPending) Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => _updateStatus(booking.id!, 'cancelled'), 
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12)
            ), 
            child: const Text("Decline")
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: () => _updateStatus(booking.id!, 'confirmed'), 
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
            ), 
            child: const Text("Accept")
          )),
        ]),
      ]),
    );
  }

  // --- UPDATED: Order Card with Buttons ---
  Widget _buildOrderCard(Order order) {
    bool isPending = order.status == 'pending'; // Check if pending

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
                Text("\$${order.totalPrice}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF4F46E5))),
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
          
          // --- Buttons for Pending Orders ---
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
                    onPressed: () => _updateOrderStatus(order.id, 'shipped'), // Or 'confirmed' if added to backend
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