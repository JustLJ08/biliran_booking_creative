import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/industry.dart';

class CategoryCard extends StatelessWidget {
  final Industry industry;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.industry,
    required this.onTap,
  });

  // Helper method to map icon codes (from Django) to Flutter Icons
  IconData _getIcon(String code) {
    switch (code) {
      case 'camera': return Icons.camera_alt_rounded;
      case 'gamepad': return Icons.sports_esports_rounded;
      case 'lightbulb': return Icons.lightbulb_rounded;
      case 'pen-tool': return Icons.design_services_rounded;
      case 'book-open': return Icons.menu_book_rounded;
      case 'mic': return Icons.mic_rounded;
      case 'palette': return Icons.palette_rounded;
      case 'music': return Icons.music_note_rounded;
      case 'landmark': return Icons.account_balance_rounded;
      default: return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF), // Indigo 50
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(industry.iconCode),
                color: const Color(0xFF4F46E5), // Indigo 600
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                industry.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF1F2937), // Gray 800
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}