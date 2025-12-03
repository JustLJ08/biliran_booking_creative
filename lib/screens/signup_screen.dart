import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
// IMPORT the screen we created in the previous step
import 'interest_selection_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  String _selectedRole = 'client'; 
  bool _isLoading = false;

  Future<void> _signup() async {
    // 1. Validation
    if (_usernameController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill in all required fields"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 2. Call Register API
    final success = await ApiService.register(
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
      _selectedRole,
    );

    if (success && mounted) {
      // --- NEW LOGIC: AUTO-LOGIN & GO TO PREFERENCES ---
      
      // Attempt to log in immediately with the new credentials
      final loginSuccess = await ApiService.login(
        _usernameController.text.trim(), 
        _passwordController.text.trim()
      );

      setState(() => _isLoading = false);

      if (loginSuccess && mounted) {
        // Success! Go to Interest Selection Screen instead of Login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Account Created! Let's personalize your feed."),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const InterestSelectionScreen(isEditMode: false)),
        );
      } else {
        // Fallback: If auto-login fails, send them to manual Login screen
        Navigator.pop(context); 
      }
      // --------------------------------------------------

    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Signup Failed. Check your email format or username."),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            "Create Account", 
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF111827),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Start your journey",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: const Color(0xFF111827)
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Create an account to browse or offer services", 
                style: TextStyle(color: Colors.grey.shade600)
              ),
              const SizedBox(height: 32),
              
              // Text Fields
              TextField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Username", 
                  prefixIcon: Icon(Icons.person_outline)
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email", 
                  prefixIcon: Icon(Icons.email_outlined)
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: "First Name"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _lastNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: "Last Name"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: "Password", 
                  prefixIcon: Icon(Icons.lock_outline)
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Modern Role Selection (Cards)
              Text(
                "I want to...", 
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildRoleCard('client', 'Hire Talent', Icons.search)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildRoleCard('creative', 'Find Work', Icons.brush)),
                ],
              ),

              const SizedBox(height: 40),
              
              // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text("Create Account"),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", style: TextStyle(color: Colors.grey.shade600)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Log In",
                      style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String role, String label, IconData icon) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade400, 
              size: 32
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}