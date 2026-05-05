import 'package:flutter/foundation.dart'; // For kIsWeb
import '../../utils/image_url_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/sub_category.dart';
import '../../models/creative.dart';
import '../../services/api_service.dart';
import 'creative_detail_screen.dart';

class CreativeListScreen extends StatefulWidget {
  final SubCategory subCategory;

  const CreativeListScreen({super.key, required this.subCategory});

  @override
  State<CreativeListScreen> createState() => _CreativeListScreenState();
}

class _CreativeListScreenState extends State<CreativeListScreen> {
  late Future<List<Creative>> futureCreatives;

  @override
  void initState() {
    super.initState();
    futureCreatives = ApiService.fetchCreatives(widget.subCategory.id);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          widget.subCategory.name, 
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: FutureBuilder<List<Creative>>(
        future: futureCreatives,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading creatives",
                style: GoogleFonts.plusJakartaSans(color: Colors.red),
              )
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "No professionals yet", 
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                      fontSize: 16
                    )
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final creative = snapshot.data![index];
              return _buildCreativeCard(creative);
            },
          );
        },
      ),
    );
  }

  Widget _buildCreativeCard(Creative creative) {
    // Construct display name from nested User object
    final displayName = "${creative.user.firstName} ${creative.user.lastName}";
    // Get role name from nested SubCategory object
    final roleName = creative.subCategory.name;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreativeDetailScreen(creative: creative)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), 
              blurRadius: 15, 
              offset: const Offset(0, 5)
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
                image: (creative.profileImageUrl != null)
                    ? DecorationImage(
                        image: NetworkImage(fixImageUrl(creative.profileImageUrl!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (creative.profileImageUrl == null)
                  ? Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16, 
                      color: const Color(0xFF111827)
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    roleName,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF6B7280), 
                      fontSize: 13,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade400),
                      const SizedBox(width: 4),
                      Text(
                        "5.0", // Hardcoded placeholder until rating is added to API
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "₱${creative.hourlyRate.toStringAsFixed(0)}/hr", 
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF10B981), // Green color for price
                          fontWeight: FontWeight.bold, 
                          fontSize: 12
                        )
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }
}