import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/creative.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';

class BookingFormScreen extends StatefulWidget {
  final Creative creative;
  final Map<String, dynamic>? selectedPackage;

  const BookingFormScreen({
    super.key,
    required this.creative,
    this.selectedPackage,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _requirementsController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  bool _isAgreed = false;

  // Optional package dropdown state
  List<Map<String, dynamic>> _availablePackages = [];
  Map<String, dynamic>? _chosenPackage;
  bool _loadingPackages = false;

  @override
  void initState() {
    super.initState();
    // If a package was passed in, use it directly
    if (widget.selectedPackage != null) {
      _chosenPackage = widget.selectedPackage;
    } else {
      // Otherwise, fetch packages for the optional dropdown
      _fetchPackages();
    }
  }

  Future<void> _fetchPackages() async {
    setState(() => _loadingPackages = true);
    try {
      final packages = await ApiService.fetchServicePackages(widget.creative.id);
      if (mounted) {
        setState(() {
          _availablePackages = packages;
          _loadingPackages = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingPackages = false);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  void _showContractDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Service Contract", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("PAYMENT TERMS AGREEMENT", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Text(
                "1. INITIAL DEPOSIT (30%):\n"
                "You agree to pay a non-refundable deposit of 30% of the total fee immediately upon booking confirmation to secure the slot.\n\n"
                "2. FINAL PAYMENT (30%):\n"
                "The remaining 70% balance is due immediately upon the successful completion of the service/project.\n\n"
                "3. CANCELLATION:\n"
                "Cancellations made less than 24 hours before the scheduled time may result in forfeiture of the deposit.\n\n"
                "4. PAYMENT PROOF:\n"
                "Please send the receipt of your 30% down payment to the provider immediately after booking to confirm your slot.",
                style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF4F46E5))),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to the payment contract to proceed.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedTime != null) {
      setState(() => _isLoading = true);

      String formattedDate = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      String formattedTime = "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00";

      // Resolve the package ID
      int? packageId;
      if (_chosenPackage != null) {
        packageId = _chosenPackage!['id'];
      }

      Booking newBooking = Booking(
        creativeId: widget.creative.id,
        date: formattedDate,
        time: formattedTime,
        requirements: _requirementsController.text,
        packageId: packageId,
      );

      bool success = await ApiService.createBooking(newBooking);

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking Request Sent Successfully!'), backgroundColor: Color(0xFF10B981)),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to make booking. Try again.'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Date and Time')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String providerName = widget.creative.user.firstName;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text("Book $providerName", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- PACKAGE INFO (if selected) ---
              if (_chosenPackage != null && widget.selectedPackage != null) _buildSelectedPackageCard(),

              // --- OPTIONAL PACKAGE DROPDOWN (if no package pre-selected) ---
              if (widget.selectedPackage == null) _buildPackageDropdown(),

              Text("Select Appointment", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
              const SizedBox(height: 20),

              // Date Picker
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: ListTile(
                  title: Text(
                    _selectedDate == null ? "Select Date" : "${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}",
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF374151)),
                  ),
                  leading: const Icon(Icons.calendar_today_rounded, color: Color(0xFF4F46E5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 12),

              // Time Picker
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: ListTile(
                  title: Text(
                    _selectedTime == null ? "Select Time" : _selectedTime!.format(context),
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF374151)),
                  ),
                  leading: const Icon(Icons.access_time_rounded, color: Color(0xFF4F46E5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: _pickTime,
                ),
              ),

              const SizedBox(height: 32),
              Text("Requirements", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
              const SizedBox(height: 12),

              TextFormField(
                controller: _requirementsController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Describe your project, event details, or specific needs...",
                  hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 14),
                  filled: true, fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (value) => value!.isEmpty ? "Please enter details" : null,
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // --- CONTRACT AGREEMENT ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24, width: 24,
                    child: Checkbox(
                      value: _isAgreed,
                      activeColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => setState(() => _isAgreed = val ?? false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _showContractDialog,
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(color: Colors.grey[700], fontSize: 13, height: 1.4),
                          children: [
                            const TextSpan(text: "I agree to pay "),
                            TextSpan(text: "30% upfront", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black)),
                            const TextSpan(text: " and the remaining "),
                            TextSpan(text: "70% upon completion", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black)),
                            const TextSpan(text: ". View full "),
                            TextSpan(text: "Contract Agreement", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                            const TextSpan(text: "."),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("Confirm Booking", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // SELECTED PACKAGE CARD (when navigated from Packages tab)
  // =========================================================================
  Widget _buildSelectedPackageCard() {
    final pkg = _chosenPackage!;
    final title = pkg['title'] ?? 'Package';
    final price = double.tryParse(pkg['price']?.toString() ?? '0') ?? 0.0;
    final deliveryTime = pkg['delivery_time'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFEEF2FF), Color(0xFFF0FDF4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF4F46E5), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Selected Package", style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF6B7280), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text("₱${price.toStringAsFixed(0)}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF10B981), fontSize: 14)),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(deliveryTime, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // OPTIONAL PACKAGE DROPDOWN (when no package pre-selected)
  // =========================================================================
  Widget _buildPackageDropdown() {
    if (_loadingPackages) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5))),
            const SizedBox(width: 12),
            Text("Loading packages...", style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      );
    }

    if (_availablePackages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Service Package (Optional)", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButtonFormField<int>(
            value: _chosenPackage?['id'],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              hintText: "Select a package or leave for hourly rate",
              hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.inventory_2_outlined, color: Color(0xFF4F46E5)),
            ),
            isExpanded: true,
            items: _availablePackages.map((pkg) {
              final price = double.tryParse(pkg['price']?.toString() ?? '0') ?? 0.0;
              return DropdownMenuItem<int>(
                value: pkg['id'],
                child: Text("${pkg['title']} — ₱${price.toStringAsFixed(0)}", style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF374151))),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                if (val == null) {
                  _chosenPackage = null;
                } else {
                  _chosenPackage = _availablePackages.firstWhere((p) => p['id'] == val);
                }
              });
            },
          ),
        ),
        if (_chosenPackage != null) ...[
          const SizedBox(height: 12),
          _buildSelectedPackageCard(),
        ] else
          const SizedBox(height: 24),
      ],
    );
  }
}