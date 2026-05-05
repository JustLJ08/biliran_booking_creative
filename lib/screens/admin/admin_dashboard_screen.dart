// lib/screens/admin/admin_dashboard_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import '../../utils/image_url_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../services/api_service.dart';
import '../../models/creative.dart';
import '../../models/product.dart';
import '../auth/login_screen.dart';

// Theme constants — matches client/provider screens
const _kPrimary = Color(0xFF4F46E5);
const _kPrimaryDark = Color(0xFF4338CA);
const _kPrimaryLight = Color(0xFFEEF2FF);
const _kBg = Color(0xFFF9FAFB);
const _kText = Color(0xFF111827);
const _kTextSub = Color(0xFF6B7280);
const _kSuccess = Color(0xFF10B981);
const _kWarning = Color(0xFFF59E0B);
const _kDanger = Color(0xFFEF4444);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<List<Creative>> _futurePending;
  late Future<List<Creative>> _futureVerified;
  late Future<List<Product>> _futureProducts;
  int _selectedIndex = 0;

  // Search State
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Debounce (optional)
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
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
                color: isApprove ? _kSuccess : _kDanger,
              ),
              const SizedBox(height: 16),
              Text(
                isApprove ? "Approve Provider?" : "Remove Provider?",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Are you sure you want to ${isApprove ? 'approve' : 'remove'} $name?",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: _kTextSub),
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
                        backgroundColor: isApprove ? _kSuccess : _kDanger,
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
          backgroundColor: isApprove ? _kSuccess : _kDanger,
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



  String _getTitle() {
    switch (_selectedIndex) {
      case 0: return "Overview";
      case 1: return "Pending Providers";
      case 2: return "Verified Providers";
      case 3: return "All Products";
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(color: _kText, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: GoogleFonts.plusJakartaSans(color: _kTextSub),
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : Text(
                _getTitle(),
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: _kText),
              ),
        backgroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded, color: _kTextSub, size: 22),
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
            icon: const Icon(Icons.logout_rounded, color: _kTextSub),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildOverviewTab(),
          _buildTabWithStatsAndList(isPending: true),
          _buildTabWithStatsAndList(isPending: false),
          _buildTabWithStatsAndProducts(),
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
            BottomNavigationBarItem(icon: Icon(Icons.pending_actions_rounded), label: 'Pending'),
            BottomNavigationBarItem(icon: Icon(Icons.verified_rounded), label: 'Verified'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Products'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: _kPrimary,
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 12),
          elevation: 0,
          onTap: (i) => setState(() => _selectedIndex = i),
        ),
      ),
    );
  }

Widget _buildEmptyState(String message, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 48),
    alignment: Alignment.center,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: _kPrimaryLight, shape: BoxShape.circle),
          child: Icon(icon, size: 48, color: _kPrimary.withOpacity(0.5)),
        ),
        const SizedBox(height: 16),
        Text(message, style: GoogleFonts.plusJakartaSans(color: _kTextSub, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

  // ---------------------------------------------------------
  //  OVERVIEW TAB — hero card + stats grid
  // ---------------------------------------------------------
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPrimary, _kPrimaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: _kPrimary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
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
                          Text("Admin Panel", style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Text("Platform Management", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
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
                        const Icon(Icons.shield_rounded, color: Colors.greenAccent, size: 16),
                        const SizedBox(width: 4),
                        Text("System Operational", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildOverviewStatCard(
                    title: "Pending",
                    icon: Icons.pending_actions_rounded,
                    future: _futurePending,
                    color: _kWarning,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOverviewStatCard(
                    title: "Verified",
                    icon: Icons.verified_rounded,
                    future: _futureVerified,
                    color: _kSuccess,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildOverviewStatCard(
              title: "Total Products",
              icon: Icons.inventory_2_rounded,
              future: _futureProducts,
              color: _kPrimary,
              onTap: () => setState(() => _selectedIndex = 3),
            ),

            const SizedBox(height: 32),

            // Recent Pending
            Text("Recent Pending", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: _kText)),
            const SizedBox(height: 12),
            FutureBuilder<List<Creative>>(
              future: _futurePending,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _kPrimary)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState("No pending providers", Icons.check_circle_outline_rounded);
                }
                final items = snapshot.data!.take(3).toList();
                return Column(
                  children: items.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildProviderCard(c, true),
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStatCard({
    required String title,
    required IconData icon,
    required Future<List<dynamic>> future,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        String count = snapshot.hasData ? "${snapshot.data!.length}" : "-";
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 16),
                Text(count, style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: _kText)),
                Text(title, style: GoogleFonts.plusJakartaSans(color: _kTextSub, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      },
    );
  }


  // ---------------------------------------------------------
  //  TAB WITH PROVIDERS + STATS PANEL
  // ---------------------------------------------------------
  Widget _buildTabWithStatsAndList({required bool isPending}) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
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
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _statCard(
                      title: "Total Products",
                      count: "$products",
                      icon: Icons.inventory_2_outlined,
                      color: _kPrimary,
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
                backgroundColor: _kPrimaryLight,
                backgroundImage: creative.profileImageUrl != null
                    ? NetworkImage(fixImageUrl(creative.profileImageUrl!))
                    : null,
                child: creative.profileImageUrl == null
                    ? Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : "U",
                        style: GoogleFonts.plusJakartaSans(
                          color: _kPrimary,
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
                        color: _kPrimaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        creative.subCategory.name,
                        style: GoogleFonts.plusJakartaSans(
                          color: _kPrimary,
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
      color: _kPrimary,
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
                      fixImageUrl(product.imageUrl!),
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
                      color: _kPrimary,
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
