import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'create_profile_screen.dart';
import 'interest_selection_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String role;
  const VerifyEmailScreen({super.key, required this.role});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String _message = "A verification code was sent to your email.";

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    final success = await ApiService.verifyOTP(_otpController.text.trim());

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email verified successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate based on role
      if (widget.role == "creative") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InterestSelectionScreen(isEditMode: false)),
        );
      }

    } else {
      setState(() => _message = "Incorrect code. Try again.");
    }
  }

  Future<void> _resendOTP() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Resending OTP..."),
        duration: Duration(seconds: 1),
      ),
    );

    bool sent = await ApiService.resendOTP();

    if (sent) {
      setState(() => _message = "New OTP sent to your email.");
    } else {
      setState(() => _message = "Failed to resend OTP.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Email"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Email Verification",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(_message, style: GoogleFonts.plusJakartaSans(color: Colors.grey)),

            const SizedBox(height: 40),
            
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter OTP",
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify"),
              ),
            ),

            const SizedBox(height: 20),
            TextButton(
              onPressed: _resendOTP,
              child: const Text("Resend Code"),
            ),
          ],
        ),
      ),
    );
  }
}
