// lib/screens/admin/admin_dashboard_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../services/api_service.dart';
import '../../models/creative.dart';
import '../../models/product.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Creative>> _futurePending;
  late Future<List<Creative>> _futureVerified;
  late Future<List<Product>> _futureProducts;
  late TabController _tabController;

  // Search State
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Debounce (optional)
  Timer? _debounce;

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
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _futurePending = ApiService.fetchPendingCreatives();
      _futureVerified = ApiService.fetchAllVerifiedCreatives();
      _futureProducts = ApiService.fetchAllProducts();
    });
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      setState(() => _searchQuery = q.trim().toLowerCase());
    });
  }

  // Confirmation window with improved visuals
  Future<void> _confirmAction(int id, String action, String name) async {
    final bool isApprove = action == 'approve';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isApprove ? Icons.verified_outlined : Icons.warning_amber_rounded,
                size: 60,
                color: isApprove ? Colors.green : Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                isApprove ? "Approve Provider?" : "Remove Provider?",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Are you sure you want to ${isApprove ? 'approve' : 'remove'} $name?",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: Colors.grey[700]),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isApprove ? const Color(0xFF10B981) : Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(isApprove ? "Approve" : "Remove"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) _handleAction(id, action);
  }

  Future<void> _handleAction(int id, String action) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Processing... Please wait",
            style: GoogleFonts.plusJakartaSans()),
        duration: const Duration(milliseconds: 700),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final success = await ApiService.manageCreativeProfile(id, action);

    if (!mounted) return;
    if (success) {
      final isApprove = action == 'approve';
      final message = isApprove
          ? "Provider Approved Successfully"
          : "Provider Removed Successfully";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isApprove ? Icons.check_circle : Icons.delete_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isApprove ? const Color(0xFF10B981) : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );

      _loadData();
    }
  }

  void _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // Fix URLs for emulator, web, local dev
  String _fixImageUrl(String url) {
    if (url.startsWith('http')) {
      if (!kIsWeb) {
        if (url.contains('127.0.0.1')) {
          return url.replaceFirst('127.0.0.1', '10.0.2.2');
        }
      }
      return url;
    }
    return kIsWeb ? "http://127.0.0.1:8000$url" : "http://10.0.2.2:8000$url";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) {
          return [
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              elevation: 4,
              backgroundColor: Colors.white,
              expandedHeight: 70,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF4F46E5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search...",
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: _onSearchChanged,
                    )
                  : Text(
                      "Admin Dashboard",
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Colors.white,
                    size: 22,
                  ),
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
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _logout,
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(55),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withOpacity(0.25),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: const [
                      Tab(text: "Pending"),
                      Tab(text: "Verified"),
                      Tab(text: "Products"),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTabWithStatsAndList(isPending: true),
            _buildTabWithStatsAndList(isPending: false),
            _buildTabWithStatsAndProducts(),
          ],
        ),
      ),
    );
  }

Widget _buildEmptyState(String message, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 24),
    alignment: Alignment.center,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 56, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}


  // ---------------------------------------------------------
  //  TAB WITH PROVIDERS + STATS PANEL
  // ---------------------------------------------------------
  Widget _buildTabWithStatsAndList({required bool isPending}) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF4F46E5),
      child: FutureBuilder<List<Creative>>(
        future: isPending ? _futurePending : _futureVerified,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];
          final filtered = list.where((c) {
            final name = "${c.user.firstName} ${c.user.lastName}".toLowerCase();
            final category = c.subCategory.name.toLowerCase();
            if (_searchQuery.isEmpty) return true;
            return name.contains(_searchQuery) || category.contains(_searchQuery);
          }).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.isEmpty ? 2 : filtered.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) return _buildStatsHeader();

              if (filtered.isEmpty) {
                return _buildEmptyState(
                  isPending ? "No pending providers" : "No verified providers",
                  isPending ? Icons.assignment_turned_in_outlined : Icons.people_outline,
                );
              }

              final creative = filtered[index - 1];
              return _buildProviderCard(creative, isPending);
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------
  //  BEAUTIFUL GLASS-LIKE STATISTICS HEADER
  // ---------------------------------------------------------
  Widget _buildStatsHeader() {
    return FutureBuilder<List<Creative>>(
      future: _futureVerified,
      builder: (context, verifiedSnap) {
        final providers = verifiedSnap.data?.length ?? 0;

        return FutureBuilder<List<Product>>(
          future: _futureProducts,
          builder: (context, productSnap) {
            final products = productSnap.data?.length ?? 0;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _statCard(
                      title: "Active Providers",
                      count: "$providers",
                      icon: Icons.people_alt_outlined,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _statCard(
                      title: "Total Products",
                      count: "$products",
                      icon: Icons.inventory_2_outlined,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const Spacer(),
              Text(
                count,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  // ---------------------------------------------------------
  //  PROVIDER CARD — PREMIUM REDESIGN
  // ---------------------------------------------------------
  Widget _buildProviderCard(Creative creative, bool isPending) {
    final fullName = "${creative.user.firstName} ${creative.user.lastName}";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isPending
              ? Colors.orange.withOpacity(0.25)
              : Colors.green.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: creative.profileImageUrl != null
                    ? NetworkImage(_fixImageUrl(creative.profileImageUrl!))
                    : null,
                child: creative.profileImageUrl == null
                    ? Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : "U",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.deepPurple,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        creative.subCategory.name,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.deepPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isPending
                      ? Colors.orange.withOpacity(0.15)
                      : Colors.green.withOpacity(0.15),
                ),
                child: Text(
                  isPending ? "Pending" : "Verified",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color:
                        isPending ? Colors.orange.shade800 : Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Email + Bio
          _buildInfoRow(Icons.email_outlined, creative.user.email),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.info_outline, creative.bio, maxLines: 2),

          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              if (isPending) ...[
                Expanded(
                  child: _buildActionButton(
                    label: "Decline",
                    color: Colors.red,
                    isOutlined: true,
                    onTap: () => _confirmAction(creative.id, 'decline', fullName),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: "Approve",
                    color: Colors.green,
                    isOutlined: false,
                    onTap: () => _confirmAction(creative.id, 'approve', fullName),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: _buildActionButton(
                    label: "Remove Provider",
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    isOutlined: true,
                    onTap: () => _confirmAction(creative.id, 'decline', fullName),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  //  INFO ROW — DISPLAY EMAIL AND BIO
  // ---------------------------------------------------------
  Widget _buildInfoRow(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  //  ACTION BUTTON — IMPROVED STYLE
  // ---------------------------------------------------------
  Widget _buildActionButton({
    required String label,
    required Color color,
    required bool isOutlined,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(10),
          border:
              isOutlined ? Border.all(color: color.withOpacity(0.6)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isOutlined ? color : Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isOutlined ? color : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  //  PRODUCT CARD — MODERN LARGE IMAGE GRID CARD
  // ---------------------------------------------------------
  // ---------------------------------------------------------
  //  TAB WITH PRODUCTS — GRID VIEW
  // ---------------------------------------------------------
  Widget _buildTabWithStatsAndProducts() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF4F46E5),
      child: FutureBuilder<List<Product>>(
        future: _futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];
          final filtered = list.where((p) {
            final name = p.name.toLowerCase();
            if (_searchQuery.isEmpty) return true;
            return name.contains(_searchQuery);
          }).toList();

          if (filtered.isEmpty) {
            return _buildEmptyState(
              "No products available",
              Icons.shopping_bag_outlined,
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _buildProductCard(filtered[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: product.imageUrl != null
                  ? Image.network(
                      _fixImageUrl(product.imageUrl!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 40),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "₱${product.price.toStringAsFixed(2)}",
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
