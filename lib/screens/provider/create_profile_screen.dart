import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';   // NEW
import '../../services/api_service.dart';
import '../../models/sub_category.dart';
import '../../models/industry.dart';
import 'dart:io'; // NEW
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'verification_pending_screen.dart';


class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _bioController = TextEditingController();
  final _rateController = TextEditingController();
  final _portfolioController = TextEditingController();

  XFile? _selectedImage; // NEW: Profile image picked by user
  Uint8List? _imageBytes; // For Web preview

  XFile? _selectedNationalId; // National ID image
  Uint8List? _nationalIdBytes; // For Web preview

  final ImagePicker _picker = ImagePicker();

  // Dropdown data
  List<Industry> _industries = [];
  List<SubCategory> _roles = [];

  // Selections
  int? _selectedIndustryId;
  int? _selectedRoleId;

  bool _isLoading = false;
  bool _isRolesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadIndustries();
  }

  // LOAD INDUSTRIES
  Future<void> _loadIndustries() async {
    try {
      final industries = await ApiService.fetchIndustries();
      setState(() => _industries = industries);
    } catch (e) {
      print("Error loading industries: $e");
    }
  }

  // LOAD ROLES
  Future<void> _loadRoles(int industryId) async {
    setState(() {
      _isRolesLoading = true;
      _roles = [];
      _selectedRoleId = null;
    });

    try {
      final roles = await ApiService.fetchSubCategories(industryId);
      setState(() => _roles = roles);
    } catch (e) {
      print("Error loading roles: $e");
    } finally {
      setState(() => _isRolesLoading = false);
    }
  }

  // IMAGE PICKER POPUP
  Future<void> _pickImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
      });
    }
  }

  // NATIONAL ID IMAGE PICKER
  Future<void> _pickNationalId() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedNationalId = image;
        _nationalIdBytes = bytes;
      });
    }
  }

  // SUBMIT PROFILE
  Future<void> _submit() async {
    if (_selectedRoleId == null ||
        _bioController.text.isEmpty ||
        _rateController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    final success = await ApiService.createCreativeProfile(
      _selectedRoleId!,
      _bioController.text,
      double.tryParse(_rateController.text) ?? 0.0,
      _portfolioController.text,
      _selectedImage,
      nationalIdImage: _selectedNationalId,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const VerificationPendingScreen()),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to create profile.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Complete Your Profile",
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo[900],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Tell clients about you",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // ----------------------------------------------------
            // PROFILE IMAGE PICKER (NEW)
            // ----------------------------------------------------
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.indigo.shade100,
                  backgroundImage: _imageBytes != null
                      ? MemoryImage(_imageBytes!) as ImageProvider
                      : null,
                  child: _selectedImage == null
                      ? const Icon(Icons.camera_alt,
                          size: 40, color: Colors.indigo)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // INDUSTRY DROPDOWN
            DropdownButtonFormField<int>(
              value: _selectedIndustryId,
              isExpanded: true,
              items: _industries
                  .map((ind) => DropdownMenuItem(value: ind.id, child: Text(ind.name)))
                  .toList(),
              onChanged: (val) {
                setState(() => _selectedIndustryId = val);
                if (val != null) _loadRoles(val);
              },
              decoration: const InputDecoration(
                labelText: "Select Industry",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 16),

            // ROLE DROPDOWN
            DropdownButtonFormField<int>(
              value: _selectedRoleId,
              isExpanded: true,
              items: _roles
                  .map((role) =>
                      DropdownMenuItem(value: role.id, child: Text(role.name)))
                  .toList(),
              onChanged: _isRolesLoading ? null : (v) => setState(() => _selectedRoleId = v),
              decoration: InputDecoration(
                labelText: _isRolesLoading ? "Loading roles..." : "Select Profession",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.work),
              ),
            ),
            const SizedBox(height: 16),

            // RATE
            TextField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Hourly Rate (₱)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),

            // BIO
            TextField(
              controller: _bioController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Bio / Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // PORTFOLIO
            TextField(
              controller: _portfolioController,
              decoration: const InputDecoration(
                labelText: "Portfolio URL (Optional)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 24),

            // --------------------------------------------------------
            // NATIONAL ID UPLOAD (RECTANGULAR CARD)
            // --------------------------------------------------------
            Text(
              "Upload National ID",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.indigo[900],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Required for provider verification",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickNationalId,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedNationalId != null
                        ? Colors.indigo
                        : Colors.indigo.shade200,
                    width: _selectedNationalId != null ? 2 : 1.5,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: _nationalIdBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          _nationalIdBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge_outlined,
                              size: 44, color: Colors.indigo.shade400),
                          const SizedBox(height: 10),
                          Text(
                            "Tap to upload National ID",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.indigo.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "JPG, PNG — clear photo of your valid ID",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // SUBMIT BUTTON
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save & Continue",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
