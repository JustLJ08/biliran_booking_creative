import 'package:flutter/foundation.dart';
import '../../utils/image_url_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/creative.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import 'booking_form_screen.dart';

class CreativeDetailScreen extends StatefulWidget {
  final Creative creative;
  const CreativeDetailScreen({super.key, required this.creative});

  @override
  State<CreativeDetailScreen> createState() => _CreativeDetailScreenState();
}

class _CreativeDetailScreenState extends State<CreativeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Product>> _futureProducts;
  late Future<List<Map<String, dynamic>>> _futurePackages;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _futureProducts = ApiService.fetchProducts(widget.creative.id);
    _futurePackages = ApiService.fetchServicePackages(widget.creative.id);
  }

  void _buyProduct(Product product) async {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This product is out of stock!"), backgroundColor: Colors.red),
      );
      return;
    }
    bool success = await ApiService.createOrder(product.id, 1);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Order Placed for ${product.name}!"),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        "${widget.creative.user.firstName} ${widget.creative.user.lastName}";
    final roleName = widget.creative.subCategory.name;
    const rating = "5.0";

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF111827),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderBackground(displayName),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: const Color(0xFF9CA3AF),
              indicatorColor: const Color(0xFF4F46E5),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "About"),
                Tab(text: "Packages"),
                Tab(text: "Shop"),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAboutTab(rating),
            _buildPackagesTab(),
            _buildShopTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeaderBackground(String displayName) {
    final roleName = widget.creative.subCategory.name;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEEF2FF), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          ClipOval(
            child: Container(
              width: 96, height: 96,
              color: const Color(0xFF4F46E5),
              child: (widget.creative.profileImageUrl != null &&
                      widget.creative.profileImageUrl!.isNotEmpty)
                  ? Image.network(
                      fixImageUrl(widget.creative.profileImageUrl!),
                      width: 96, height: 96, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Center(
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
                          style: GoogleFonts.plusJakartaSans(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
                        style: GoogleFonts.plusJakartaSans(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(displayName, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
          Text(roleName, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF6B7280), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingFormScreen(creative: widget.creative))),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            "Book Now • ₱${widget.creative.hourlyRate.toStringAsFixed(0)}/hr",
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // ABOUT TAB
  // =========================================================================
  Widget _buildAboutTab(String rating) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Rating", "⭐ $rating"),
              _buildStatItem("Experience", "Verified"),
              _buildStatItem("Response", "1 hr"),
            ],
          ),
          const SizedBox(height: 32),
          Text("Biography", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            widget.creative.bio.isNotEmpty ? widget.creative.bio : "No bio provided.",
            style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF4B5563), height: 1.6),
          ),
          if (widget.creative.portfolioUrl != null && widget.creative.portfolioUrl!.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text("Portfolio", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.creative.portfolioUrl!,
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B7280))),
      ],
    );
  }

  // =========================================================================
  // PACKAGES TAB
  // =========================================================================
  Widget _buildPackagesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futurePackages,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("No service packages available", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 15)),
                const SizedBox(height: 8),
                Text("You can still book by hourly rate.", textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 13)),
              ],
            ),
          );
        }

        final packages = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: packages.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildPackageCard(packages[index], isPopular: index == 0),
        );
      },
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg, {bool isPopular = false}) {
    final title = pkg['title'] ?? 'Untitled';
    final description = pkg['description'] ?? '';
    final price = double.tryParse(pkg['price']?.toString() ?? '0') ?? 0.0;
    final deliveryTime = pkg['delivery_time'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPopular ? const Color(0xFF4F46E5) : const Color(0xFFF3F4F6), width: isPopular ? 2 : 1),
        boxShadow: [BoxShadow(color: isPopular ? const Color(0xFF4F46E5).withOpacity(0.08) : Colors.black.withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(color: Color(0xFF4F46E5), borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18))),
              child: Center(child: Text("⭐ MOST POPULAR", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2))),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                const SizedBox(height: 8),
                Text(description, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF6B7280), height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text("₱${price.toStringAsFixed(0)}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF10B981))),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule_rounded, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(deliveryTime, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingFormScreen(creative: widget.creative, selectedPackage: pkg))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? const Color(0xFF4F46E5) : const Color(0xFFEEF2FF),
                      foregroundColor: isPopular ? Colors.white : const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text("Book with this Package", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SHOP TAB
  // =========================================================================
  Widget _buildShopTab() {
    return FutureBuilder<List<Product>>(
      future: _futureProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("No products for sale", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final product = snapshot.data![index];
            final hasImage = product.imageUrl != null;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3F4F6)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: hasImage
                          ? Image.network(fixImageUrl(product.imageUrl!), fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade400, size: 32))
                          : Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade400, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF111827))),
                          const SizedBox(height: 4),
                          Text(product.description, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Text("₱${product.price.toStringAsFixed(2)}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                          const SizedBox(height: 4),
                          Text("Stock: ${product.stock}", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: product.stock > 0 ? const Color(0xFF6B7280) : Colors.red)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _buyProduct(product),
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      color: const Color(0xFF4F46E5),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFEEF2FF)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}