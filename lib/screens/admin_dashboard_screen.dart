import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async'; // For debouncing if needed

import '../services/api_service.dart';
import '../models/creative.dart';
import '../models/product.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late Future<List<Creative>> _futurePending;
  late Future<List<Creative>> _futureVerified;
  late Future<List<Product>> _futureProducts;
  late TabController _tabController;
  
  // Search State
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Refactored to return Future for RefreshIndicator
  Future<void> _loadData() async {
    setState(() {
      _futurePending = ApiService.fetchPendingCreatives();
      _futureVerified = ApiService.fetchAllVerifiedCreatives();
      _futureProducts = ApiService.fetchAllProducts();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  // --- ENHANCEMENT: Safety Confirmation Dialog ---
  Future<void> _confirmAction(int id, String action, String name) async {
    final bool isApprove = action == 'approve';
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApprove ? "Approve Provider?" : "Decline/Remove Provider?"),
        content: Text("Are you sure you want to ${isApprove ? 'approve' : 'remove'} $name?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? const Color(0xFF10B981) : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isApprove ? "Confirm Approve" : "Confirm Remove"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _handleAction(id, action);
    }
  }

  Future<void> _handleAction(int id, String action) async {
    // Show loading overlay or simple snackbar "Processing..."
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Processing request..."), duration: Duration(milliseconds: 500)),
    );

    bool success = await ApiService.manageCreativeProfile(id, action);

    if (success && mounted) {
      String message = action == 'approve' ? "Provider Approved Successfully" : "Provider Request Declined";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(action == 'approve' ? Icons.check_circle : Icons.info, color: Colors.white),
              const SizedBox(width: 10),
              Text(message, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: action == 'approve' ? const Color(0xFF10B981) : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
      _loadData(); 
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Action failed. Please try again."), backgroundColor: Colors.red),
      );
    }
  }

  void _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  String _fixImageUrl(String url) {
    if (url.startsWith('http')) {
      if (!kIsWeb) {
        if (url.contains('127.0.0.1')) return url.replaceFirst('127.0.0.1', '10.0.2.2');
        if (url.contains('localhost')) return url.replaceFirst('localhost', '10.0.2.2');
      }
      if (kIsWeb && url.contains('10.0.2.2')) return url.replaceFirst('10.0.2.2', '127.0.0.1');
      return url;
    } else {
      String base = kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
      return '$base$url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Slightly darker grey for better contrast
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: _isSearching 
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111827)),
                    decoration: InputDecoration(
                      hintText: "Search providers or products...",
                      border: InputBorder.none,
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                    ),
                    onChanged: _onSearchChanged,
                  )
                : Text("Admin Panel", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
              backgroundColor: Colors.white,
              floating: true,
              snap: true,
              pinned: true,
              elevation: 2,
              iconTheme: const IconThemeData(color: Colors.black87),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.grey[700]),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchQuery = "";
                        _searchController.clear();
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  onPressed: _logout,
                )
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF4F46E5),
                indicatorWeight: 3,
                labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Pending"),
                  Tab(text: "Verified"),
                  Tab(text: "Products"),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRefreshableList(isPending: true),
            _buildRefreshableList(isPending: false),
            _buildRefreshableProductGrid(),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildRefreshableList({required bool isPending}) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF4F46E5),
      child: FutureBuilder<List<Creative>>(
        future: isPending ? _futurePending : _futureVerified,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(isPending ? "No pending requests" : "No verified providers", Icons.assignment_turned_in_outlined);
          }

          // Search Filter Logic
          final data = snapshot.data!.where((c) {
            final name = "${c.user.firstName} ${c.user.lastName}".toLowerCase();
            final category = c.subCategory.name.toLowerCase();
            return name.contains(_searchQuery) || category.contains(_searchQuery);
          }).toList();

          if (data.isEmpty) return _buildEmptyState("No results found", Icons.search_off);

          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final creative = data[index];
              return _buildProviderCard(creative, isPending);
            },
          );
        },
      ),
    );
  }

  Widget _buildRefreshableProductGrid() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: FutureBuilder<List<Product>>(
        future: _futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState("No products listed", Icons.inventory_2_outlined);
          }

          // Search Filter Logic
          final data = snapshot.data!.where((p) {
            return p.name.toLowerCase().contains(_searchQuery);
          }).toList();

          if (data.isEmpty) return _buildEmptyState("No products found", Icons.search_off);

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.70,
            ),
            itemCount: data.length,
            itemBuilder: (context, index) {
              return _buildProductCard(data[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return ListView( // ListView needed for RefreshIndicator to work on empty states
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(message, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(Creative creative, bool isPending) {
    final fullName = "${creative.user.firstName} ${creative.user.lastName}";
    
    return Card(
      elevation: 0, // Flat design with border looks cleaner
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navigate to Detail Screen
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("View full details for $fullName")));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero( // Nice animation if you navigate to detail page
                    tag: 'avatar_${creative.id}',
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFEEF2FF),
                      backgroundImage: (creative.profileImageUrl != null) 
                          ? NetworkImage(_fixImageUrl(creative.profileImageUrl!)) 
                          : null,
                      child: (creative.profileImageUrl == null) 
                          ? Text(
                              fullName.isNotEmpty ? fullName[0].toUpperCase() : "U", 
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5), fontSize: 20)
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            creative.subCategory.name,
                            style: GoogleFonts.plusJakartaSans(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Indicator Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPending ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPending ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                      )
                    ),
                    child: Text(
                      isPending ? "Pending" : "Verified", 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, 
                        color: isPending ? Colors.orange[800] : Colors.green[800], 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.email_outlined, creative.user.email),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.info_outline, creative.bio, maxLines: 2),
              
              const Divider(height: 30),
              
              // Action Buttons
              Row(
                children: [
                  if (isPending) ...[
                    Expanded(
                      child: _buildActionButton(
                        label: "Decline", 
                        color: Colors.red, 
                        isOutlined: true,
                        onTap: () => _confirmAction(creative.id, 'decline', fullName)
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        label: "Approve", 
                        color: const Color(0xFF10B981), 
                        isOutlined: false,
                        onTap: () => _confirmAction(creative.id, 'approve', fullName)
                      ),
                    ),
                  ] else ...[
                     Expanded(
                      child: _buildActionButton(
                        label: "Remove Provider", 
                        color: Colors.red, 
                        isOutlined: true,
                        icon: Icons.delete_outline,
                        onTap: () => _confirmAction(creative.id, 'decline', fullName)
                      ),
                    ),
                  ]
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label, 
    required Color color, 
    required bool isOutlined, 
    required VoidCallback onTap,
    IconData? icon
  }) {
    return Material(
      color: isOutlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: isOutlined ? BoxDecoration(
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8)
          ) : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 16, color: isOutlined ? color : Colors.white), const SizedBox(width: 8)],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: isOutlined ? color : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.imageUrl != null 
                    ? Image.network(
                        _fixImageUrl(product.imageUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[100], child: Icon(Icons.broken_image, color: Colors.grey[400])),
                      )
                    : Container(color: Colors.grey[100], child: Icon(Icons.image, color: Colors.grey[400])),
                  
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        "\$${product.price.toStringAsFixed(0)}",
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ID: #${product.id}",
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text, 
            style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontSize: 13),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}