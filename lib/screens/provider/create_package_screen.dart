import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

// Design tokens matching the existing system
const _kPrimary = Color(0xFF4F46E5);
const _kText = Color(0xFF111827);

class CreatePackageScreen extends StatefulWidget {
  /// Pass an existing package map to enter edit mode, or null for create mode.
  final Map<String, dynamic>? existingPackage;
  const CreatePackageScreen({super.key, this.existingPackage});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _deliveryController = TextEditingController();

  bool _isLoading = false;

  bool get _isEditMode => widget.existingPackage != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final pkg = widget.existingPackage!;
      _titleController.text = pkg['title'] ?? '';
      _descController.text = pkg['description'] ?? '';
      _priceController.text = (pkg['price'] ?? '').toString();
      _deliveryController.text = pkg['delivery_time'] ?? '';
    }
  }

  Future<void> _submit() async {
    // Validation
    if (_titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _deliveryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool success;

      if (_isEditMode) {
        success = await ApiService.updateServicePackage(
          packageId: widget.existingPackage!['id'],
          title: _titleController.text,
          description: _descController.text,
          price: double.tryParse(_priceController.text) ?? 0.0,
          deliveryTime: _deliveryController.text,
        );
      } else {
        final creativeId = await ApiService.getMyCreativeId();
        if (creativeId == null) {
          throw Exception("Profile not found. Please login again.");
        }

        success = await ApiService.createServicePackage(
          creativeId: creativeId,
          title: _titleController.text,
          description: _descController.text,
          price: double.tryParse(_priceController.text) ?? 0.0,
          deliveryTime: _deliveryController.text,
        );
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditMode
              ? "Package Updated Successfully!"
              : "Package Created Successfully!"),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true); // return true to signal refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to save package. Check server logs."),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          _isEditMode ? "Edit Package" : "Create Package",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: _kText,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _kText,
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Icon ---
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isEditMode
                      ? Icons.edit_note_rounded
                      : Icons.design_services_rounded,
                  size: 44,
                  color: _kPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _isEditMode
                    ? "Update your service package details"
                    : "Define a service package for clients to book",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // --- Title ---
            _buildLabel("Package Title"),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: _inputDecoration(
                hint: "e.g. Wedding Photography — Full Day",
                icon: Icons.title_rounded,
              ),
            ),
            const SizedBox(height: 20),

            // --- Description ---
            _buildLabel("Description"),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: _inputDecoration(
                hint: "What's included in this package?",
                icon: Icons.description_outlined,
              ),
            ),
            const SizedBox(height: 20),

            // --- Price & Delivery Time ---
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Price (₱)"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          hint: "5000",
                          icon: Icons.payments_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Delivery Time"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _deliveryController,
                        decoration: _inputDecoration(
                          hint: "e.g. 3-5 days",
                          icon: Icons.schedule_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 36),

            // --- Submit Button ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditMode ? "Update Package" : "Create Package",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _kText,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: _kPrimary.withOpacity(0.5), size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kPrimary, width: 1.5),
      ),
    );
  }
}
