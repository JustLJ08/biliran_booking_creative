import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';   // NEW
import '../services/api_service.dart';
import '../models/sub_category.dart';
import '../models/industry.dart';
import 'provider_dashboard_screen.dart';
import 'dart:io'; // NEW
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
      setState(() {
        _selectedImage = image;
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
      _selectedImage, // NEW — send image to backend
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProviderDashboardScreen()),
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
                  backgroundImage: _selectedImage != null
                      ? FileImage(
                          File(_selectedImage!.path),
                        )
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
