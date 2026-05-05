import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/client/home_screen.dart';
import 'screens/provider/provider_dashboard_screen.dart';
import 'screens/provider/create_profile_screen.dart';
import 'screens/provider/verification_pending_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/auth/preference_screen.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CreativeBookingApp());
}

class CreativeBookingApp extends StatelessWidget {
  const CreativeBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Booking Creative',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5), // Indigo 600
          primary: const Color(0xFF4F46E5),
          secondary: const Color(0xFF7C3AED), // Violet 600
          background: const Color(0xFFF9FAFB), // Cool Gray 50
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF111827), // Gray 900
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade500),
          prefixIconColor: Colors.grey.shade400,
        ),
      ),
      home: const SplashRouter(),
    );
  }
}

/// Checks if the user has a saved session and routes accordingly.
/// If no session is found, shows the login screen.
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final role = prefs.getString('role');

    if (!mounted) return;

    // No saved session → go to login
    if (userId == null || role == null) {
      _navigateTo(const LoginScreen());
      return;
    }

    final normalizedRole = role.trim().toLowerCase();

    // --- ADMIN ---
    if (normalizedRole.contains("admin")) {
      _navigateTo(const AdminDashboardScreen());
      return;
    }

    // --- CREATIVE / PROVIDER ---
    if (normalizedRole == 'creative' || normalizedRole == 'creative professional') {
      try {
        final verification = await ApiService.checkCreativeVerified();
        bool hasProfile = verification["has_profile"] ?? false;
        bool isVerified = verification["is_verified"] ?? false;

        if (!mounted) return;

        if (!hasProfile) {
          _navigateTo(const CreateProfileScreen());
        } else if (!isVerified) {
          _navigateTo(const VerificationPendingScreen());
        } else {
          _navigateTo(const ProviderDashboardScreen());
        }
      } catch (e) {
        // If verification check fails (e.g. no network), go to login
        if (mounted) _navigateTo(const LoginScreen());
      }
      return;
    }

    // --- CLIENT ---
    try {
      bool hasPrefs = await ApiService.checkPreferences();
      if (!mounted) return;

      if (hasPrefs) {
        _navigateTo(const HomeScreen());
      } else {
        _navigateTo(const PreferenceScreen());
      }
    } catch (e) {
      if (mounted) _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a branded splash while checking session
    return const Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4F46E5),
        ),
      ),
    );
  }
}