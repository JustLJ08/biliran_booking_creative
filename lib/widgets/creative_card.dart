import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/creative.dart';

class CreativeCard extends StatelessWidget {
  final Creative creative;
  final VoidCallback onTap; // For clicking the card (Profile)
  final VoidCallback onBook; // For clicking the Book button

  const CreativeCard({
    super.key,
    required this.creative,
    required this.onTap,
    required this.onBook,
  });

  // Helper to fix localhost image URLs (Stateless version)
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
    // Construct names from nested objects
    final displayName = "${creative.user.firstName} ${creative.user.lastName}";
    final roleName = creative.subCategory.name;
    const rating = "5.0"; // Placeholder

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0, // Using manual shadow via Container decoration usually looks better, but Card is fine with custom shape
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Avatar with Image Support
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  image: (creative.profileImageUrl != null)
                      ? DecorationImage(
                          image: NetworkImage(_fixImageUrl(creative.profileImageUrl!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (creative.profileImageUrl == null)
                    ? Center(
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roleName,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "\$${creative.hourlyRate.toStringAsFixed(0)}/hr",
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF10B981), // Emerald
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "•   ⭐ $rating",
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF6B7280),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Action Buttons
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: onBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: Text(
                          "Book Now", 
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}