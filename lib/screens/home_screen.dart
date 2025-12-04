// ignore_for_file: prefer_const_constructors, deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/industry.dart';
import '../models/sub_category.dart';
import '../models/product.dart';
import '../models/creative.dart'; 
import 'sub_category_screen.dart';
import 'my_bookings_screen.dart';
import 'creative_list_screen.dart';
import 'login_screen.dart';
import 'interest_selection_screen.dart';
import 'creative_detail_screen.dart'; 

// Define theme colors for consistency
const kPrimaryColor = Color(0xFF4F46E5); // Indigo 600
const kPrimaryLight = Color(0xFFEEF2FF); // Indigo 50
const kTextPrimary = Color(0xFF111827); // Gray 900
const kTextSecondary = Color(0xFF6B7280); // Gray 500
const kBgCanvas = Color(0xFFF9FAFB); // Gray 50
const kSuccessColor = Color(0xFF10B981); // Emerald 500

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Futures for data fetching
  late Future<List<Creative>> _futureRecommended;
  late Future<List<Industry>> _futureIndustries;
  late Future<List<Product>> _futureAllProducts;
  
  List<SubCategory>? _searchResults;
  final TextEditingController _searchController = TextEditingController();
  
  int _selectedIndex = 0;
  bool _isSearching = false;
  bool _showAllCategories = false;

  @override
  void initState() {
    super.initState();
    _refreshData(); 
  }

  void _refreshData() {
    setState(() {
      _futureRecommended = ApiService.fetchRecommendedCreatives();
      _futureIndustries = ApiService.fetchIndustries();
      _futureAllProducts = ApiService.fetchAllProducts();
    });
  }

  Future<void> _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = null;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await ApiService.searchSubCategories(value);
      setState(() => _searchResults = results);
    } catch (e) {
      print("Search error: $e");
    }
  }

  // --- E-COMMERCE ORDER LOGIC WITH CONTRACT ---
  void _showOrderDialog(Product product) {
    int quantity = 1;
    bool isAgreed = false; // Track agreement status

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text("Order ${product.name}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              // FIX 1: Wrap content in SingleChildScrollView to prevent overflow
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // FIX 2: Use stretch to fill width instead of double.infinity on image
                  crossAxisAlignment: CrossAxisAlignment.stretch, 
                  children: [
                    if (product.imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _fixImageUrl(product.imageUrl!),
                            height: 120,
                            // FIX 3: Removed width: double.infinity (Caused isFinite crash)
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        ),
                      ),
                    // Center the text manually since we used crossAxisAlignment.stretch
                    Text(
                      "Price per unit: \$${product.price.toStringAsFixed(2)}", 
                      style: GoogleFonts.plusJakartaSans(color: kTextSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildQuantityButton(Icons.remove, () => quantity > 1 ? setStateDialog(() => quantity--) : null),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text("$quantity", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                        _buildQuantityButton(Icons.add, () => quantity < product.stock ? setStateDialog(() => quantity++) : null),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Total: \$${(product.price * quantity).toStringAsFixed(2)}", 
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: kPrimaryColor, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    
                    // --- CONTRACT AGREEMENT CHECKBOX ---
                    Row(
                      children: [
                        Checkbox(
                          value: isAgreed, 
                          activeColor: kPrimaryColor,
                          onChanged: (val) {
                            setStateDialog(() => isAgreed = val ?? false);
                          }
                        ),
                        Expanded(
                          child: Wrap(
                            children: [
                              Text("I agree to the ", style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                              InkWell(
                                onTap: _showTermsDialog, // Function to show full text
                                child: Text("Terms of Service Agreement", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kPrimaryColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                              ),
                            ],
                          ),
                        )
                      ],
                    )
                    // -----------------------------------
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.plusJakartaSans(color: kTextSecondary))),
                ElevatedButton(
                  // Disable button if not agreed
                  onPressed: isAgreed 
                    ? () {
                        Navigator.pop(context);
                        _processOrder(product, quantity);
                      }
                    : null, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor, 
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                  ),
                  child: Text("Confirm Order", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- TERMS DIALOG ---
  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Terms of Agreement"),
        content: const SingleChildScrollView(
          child: Text(
            "1. PAYMENT: You agree to pay the total amount shown.\n\n"
            "2. REFUNDS: Refunds are only available within 24 hours of purchase.\n\n"
            "3. DELIVERY: Physical goods will be shipped within 3 business days.\n\n"
            "4. LIABILITY: We are not liable for delays caused by third-party carriers.\n\n"
            "By proceeding, you enter into a binding contract with the provider."
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
      ),
    );
  }
  
  Widget _buildQuantityButton(IconData icon, VoidCallback? onPressed) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: IconButton(icon: Icon(icon), onPressed: onPressed, color: kTextPrimary, splashRadius: 24),
    );
  }

  Future<void> _processOrder(Product product, int quantity) async {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing order..."), duration: Duration(seconds: 1)));
      bool success = await ApiService.createOrder(product.id, quantity);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully ordered!"), backgroundColor: kSuccessColor));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to place order."), backgroundColor: Colors.red));
        }
      }
  }

  // --- HELPER: Fix Image URLs ---
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

  // --- ICON LOGIC ---
  IconData _getIconData(String code) {
    final c = code.toLowerCase();
    if (c.contains('audio') || c.contains('camera') || c.contains('visual') || c.contains('media')) {
      return Icons.video_camera_back_rounded;
    } else if (c.contains('digital') || c.contains('interactive')) {
      return Icons.touch_app_rounded;
    } else if (c.contains('creative') || c.contains('service')) {
      return Icons.auto_awesome_rounded;
    } else if (c.contains('design') || c.contains('art') || c.contains('brush')) {
      return Icons.palette_rounded;
    } else if (c.contains('tech') || c.contains('computer') || c.contains('code')) {
      return Icons.terminal_rounded;
    } else if (c.contains('music')) {
      return Icons.music_note_rounded;
    }
    return Icons.grid_view_rounded;
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgCanvas,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),          
          const MyBookingsScreen(),
          _buildPlaceholderTab("Inox Coming Soon"),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Bookings'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Inbox'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0, 
          onTap: _onItemTapped,
        ),
      ),
    );
  }


//===========================================
//           Home TAB
// ==========================================
  
  
  Widget _buildHomeTab() {
    return SafeArea(
      child: RefreshIndicator(
        color: kPrimaryColor,
        backgroundColor: Colors.white,
        onRefresh: () async => _refreshData(),
        child: SingleChildScrollView( 
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              
              if (_isSearching) 
                _buildSearchResults()
              else ...[
                const SizedBox(height: 24), 

                // 1. Recommended Providers
                _buildRecommendedSection(),

                const SizedBox(height: 32),

                // 2. All Categories Grid
                _buildCategoriesSection(),

                const SizedBox(height: 32),

                // 3. Product Feed
                _buildProductFeedSection(),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }


//=========================================
//   Profile Tab
//=========================================


  Widget _buildProfileTab() {
  return SafeArea(
    child: Column(
      children: [
        const SizedBox(height: 32),
        CircleAvatar(
          radius: 45,
          backgroundColor: kPrimaryLight,
          child: const Icon(Icons.person_rounded, size: 50, color: kPrimaryColor),
        ),
        const SizedBox(height: 16),
        Text(
          "My Profile",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 24),

        ListTile(
          leading: const Icon(Icons.edit_rounded, color: kPrimaryColor),
          title: Text("Edit Profile", style: GoogleFonts.plusJakartaSans()),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () {
            // TODO: connect to profile settings page
          },
        ),

        ListTile(
          leading: const Icon(Icons.favorite_rounded, color: kPrimaryColor),
          title: Text("Favorites", style: GoogleFonts.plusJakartaSans()),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () {},
        ),

        ListTile(
          leading: const Icon(Icons.settings_rounded, color: kPrimaryColor),
          title: Text("Settings", style: GoogleFonts.plusJakartaSans()),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () {},
        ),

        const Spacer(),

        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              "Logout",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        )
      ],
    ),
  );
}


  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: kPrimaryColor.withOpacity(0.05), blurRadius: 25, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CreativeBook",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26, fontWeight: FontWeight.w800, color: kTextPrimary, letterSpacing: -0.5
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Find perfect talent & products",
                      style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 22),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                     boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "Search services...",
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                      suffixIcon: _isSearching 
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged(''); 
                              },
                            ) 
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade100)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kPrimaryColor, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(16),
                   boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                  onPressed: () {}, 
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onActionTap, {String actionText = "See All"}) {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w700, color: kTextPrimary),
              ),
              if (onActionTap != null)
              InkWell(
                onTap: onActionTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
                  child: Text(
                    actionText, 
                    style: GoogleFonts.plusJakartaSans(color: kPrimaryColor, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Recommended Providers", () {
             Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const InterestSelectionScreen(isEditMode: true))
                  ).then((_) => _refreshData());
        }, actionText: "Edit Prefs"),
        const SizedBox(height: 12),
        SizedBox(
          height: 215, 
          child: FutureBuilder<List<Creative>>(
            future: _futureRecommended,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: kPrimaryColor)));
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                 return _buildEmptyStateCard();
              }

              final recommended = snapshot.data!;
              
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: recommended.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final creative = recommended[index];
                  return _buildProviderCard(creative);
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyStateCard() {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InterestSelectionScreen(isEditMode: true))),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))]
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
                      child: const Icon(Icons.add_reaction_rounded, color: kPrimaryColor, size: 32)
                  ),
                  const SizedBox(height: 16),
                  Text("Personalize your feed", style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                   const SizedBox(height: 4),
                  Text("Tap to select your interests", style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13)),
                ],
              ),
            ),
          ),
        );
  }

  Widget _buildProviderCard(Creative creative) {
    return Container(
      width: 165,
      margin: const EdgeInsets.only(bottom: 8, top: 4), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8), spreadRadius: -5),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreativeDetailScreen(creative: creative)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kPrimaryLight, width: 3),
                         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: CircleAvatar(
                      radius: 30, 
                      backgroundColor: kPrimaryLight,
                      backgroundImage: (creative.profileImageUrl != null) 
                          ? NetworkImage(_fixImageUrl(creative.profileImageUrl!)) 
                          : null,
                      child: (creative.profileImageUrl == null) 
                          ? Text(
                              creative.user.firstName.isNotEmpty ? creative.user.firstName[0].toUpperCase() : "U", 
                              style: GoogleFonts.plusJakartaSans(color: kPrimaryColor, fontWeight: FontWeight.w800, fontSize: 20)
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "${creative.user.firstName} ${creative.user.lastName}",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: kTextPrimary),
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  creative.subCategory.name, 
                  style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "\$${creative.hourlyRate.toStringAsFixed(0)}",
                      style: GoogleFonts.plusJakartaSans(color: kPrimaryColor, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16)
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      children: [
         _buildSectionHeader("All Categories", () {
             setState(() {
                    _showAllCategories = !_showAllCategories; 
                  });
         }, actionText: _showAllCategories ? "Show Less" : "See All"),
        const SizedBox(height: 12),
        FutureBuilder<List<Industry>>(
          future: _futureIndustries,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            
            final allIndustries = snapshot.data!;
            final displayCount = _showAllCategories ? allIndustries.length : (allIndustries.length > 4 ? 4 : allIndustries.length);
            final displayList = allIndustries.take(displayCount).toList();

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, 
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: 0.75, 
              ),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final industry = displayList[index];
                return _buildCategoryCircle(industry);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCircle(Industry industry) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => SubCategoryScreen(industry: industry)));
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, kPrimaryLight]
              ),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: kPrimaryColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8), spreadRadius: -2),
              ],
            ),
            child: Icon(_getIconData(industry.iconCode), color: kPrimaryColor, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            industry.name,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: kTextPrimary, height: 1.2),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProductFeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Popular Products", null),
        const SizedBox(height: 16),
        FutureBuilder<List<Product>>(
          future: _futureAllProducts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: kPrimaryColor)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text("No products found.", style: GoogleFonts.plusJakartaSans(color: kTextSecondary)),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => _buildProductCard(snapshot.data![index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    bool hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8), spreadRadius: -5)],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showOrderDialog(product), 
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kBgCanvas,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: hasImage
                          ? Image.network(
                              _fixImageUrl(product.imageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image_rounded, color: Colors.grey[300], size: 40),
                            )
                          : Icon(Icons.image_rounded, color: Colors.grey[300], size: 48),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: kTextPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                     Text(
                      product.description,
                      style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                     const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "\$${product.price.toStringAsFixed(2)}",
                          style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults == null) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: kPrimaryColor)));
    if (_searchResults!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade200),
              const SizedBox(height: 24),
              Text("No services found", style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
               const SizedBox(height: 8),
              Text("Try searching for something else.", style: GoogleFonts.plusJakartaSans(color: kTextSecondary)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _searchResults!.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final subCategory = _searchResults![index];
        return Container(
           decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CreativeListScreen(subCategory: subCategory)));
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.work_outline_rounded, color: kPrimaryColor, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(subCategory.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16, color: kTextPrimary)),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade300),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.construction_rounded, size: 64, color: Colors.grey.shade300),
         const SizedBox(height: 16),
        Text(title, style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontWeight: FontWeight.w600, fontSize: 18)),
      ],
    ));
  }
}