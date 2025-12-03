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
import 'creative_detail_screen.dart'; // <--- IMPORTANT IMPORT

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
      // 1. Fetch Providers matching user's sub-category interests
      _futureRecommended = ApiService.fetchRecommendedCreatives();
      
      // 2. Fetch standard data
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

  // --- E-COMMERCE ORDER LOGIC ---
  void _showOrderDialog(Product product) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Order ${product.name}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (product.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _fixImageUrl(product.imageUrl!),
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                  Text("Price per unit: \$${product.price.toStringAsFixed(2)}"),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: quantity > 1 ? () => setStateDialog(() => quantity--) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text("$quantity", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: quantity < product.stock ? () => setStateDialog(() => quantity++) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Total: \$${(product.price * quantity).toStringAsFixed(2)}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _processOrder(product, quantity);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                  child: const Text("Confirm Order"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processOrder(Product product, int quantity) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing order..."), duration: Duration(seconds: 1)));
    
    bool success = await ApiService.createOrder(product.id, quantity);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Successfully ordered ${product.name}!"), 
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to place order. Please try again."), 
          backgroundColor: Colors.red,
        ));
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
      backgroundColor: const Color(0xFFF8F9FE),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),          
          const MyBookingsScreen(), 
          _buildPlaceholderTab(2), 
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4F46E5),
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 15,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: RefreshIndicator(
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
                const SizedBox(height: 16), 

                // 1. Recommended Providers (Creatives)
                _buildRecommendedSection(),

                const SizedBox(height: 16),

                // 2. All Categories Grid
                _buildCategoriesSection(),

                const SizedBox(height: 16),

                // 3. Product Feed
                _buildProductFeedSection(),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
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
                  Text(
                    "CreativeBook",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Find perfect talent & products",
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
              InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Search anything...",
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280), size: 20),
                      suffixIcon: _isSearching 
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged(''); 
                              },
                            ) 
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  onPressed: () {}, 
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- RECOMMENDED SECTION ---
  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recommended Providers",
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const InterestSelectionScreen(isEditMode: true))
                  ).then((_) => _refreshData());
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    "Edit", 
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: FutureBuilder<List<Creative>>(
            future: _futureRecommended,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)));
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                 return Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 24),
                   child: InkWell(
                     onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InterestSelectionScreen(isEditMode: true))),
                     child: Container(
                       height: 100,
                       alignment: Alignment.center,
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                       ),
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           const Icon(Icons.add_reaction_outlined, color: Colors.grey),
                           const SizedBox(height: 8),
                           Text("Tap to personalize your feed", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                         ],
                       ),
                     ),
                   ),
                 );
              }

              final recommended = snapshot.data!;
              
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: recommended.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 12),
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

  // --- CLICKABLE PROVIDER CARD ---
  Widget _buildProviderCard(Creative creative) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(bottom: 4), // Margin for shadow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 8, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          // --- NAVIGATION TO DETAIL SCREEN ---
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreativeDetailScreen(creative: creative),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFEEF2FF),
                    backgroundImage: (creative.profileImageUrl != null) 
                        ? NetworkImage(_fixImageUrl(creative.profileImageUrl!)) 
                        : null,
                    child: (creative.profileImageUrl == null) 
                        ? Text(
                            creative.user.firstName.isNotEmpty ? creative.user.firstName[0].toUpperCase() : "U", 
                            style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 20)
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "${creative.user.firstName} ${creative.user.lastName}",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1F2937)),
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  creative.subCategory.name, 
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 11),
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "\$${creative.hourlyRate.toStringAsFixed(0)}/hr",
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Icon(Icons.arrow_circle_right_outlined, color: Color(0xFF4F46E5), size: 24),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "All Categories",
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAllCategories = !_showAllCategories; 
                  });
                },
                child: Text(
                  _showAllCategories ? "Show Less" : "See All",
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7, 
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
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(_getIconData(industry.iconCode), color: const Color(0xFF4F46E5), size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            industry.name,
            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF4B5563)),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Popular Products",
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Product>>(
          future: _futureAllProducts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text("No products found.", style: TextStyle(color: Colors.grey[500])),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.70,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: hasImage
                      ? Image.network(
                          _fixImageUrl(product.imageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40),
                        )
                      : Icon(Icons.image_outlined, color: Colors.grey[300], size: 40),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: const Icon(Icons.favorite_border_rounded, size: 16, color: Color(0xFFEF4444)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF111827)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "\$${product.price.toStringAsFixed(2)}",
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    InkWell(
                      onTap: () => _showOrderDialog(product),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults == null) return const Center(child: CircularProgressIndicator());
    if (_searchResults!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text("No roles found", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500)),
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
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final subCategory = _searchResults![index];
        return InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => CreativeListScreen(subCategory: subCategory)));
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.work_outline, color: Color(0xFF4F46E5), size: 20),
                ),
                const SizedBox(width: 16),
                Text(subCategory.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16)),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderTab(int index) {
    return Center(child: Text("Coming Soon", style: GoogleFonts.plusJakartaSans()));
  }
}