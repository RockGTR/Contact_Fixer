import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/settings_provider.dart';
import 'services/rate_limit_tracker.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RateLimitTracker()),
        ChangeNotifierProvider(
          create: (context) {
            final auth = AuthProvider();
            auth.initialize();
            return auth;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ContactsProvider>(
          create: (context) => ContactsProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) =>
              previous ?? ContactsProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SettingsProvider>(
          create: (context) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            final settings = SettingsProvider(auth);
            settings.initialize();
            return settings;
          },
          update: (context, auth, previous) {
            if (previous != null) return previous;
            final settings = SettingsProvider(auth);
            settings.initialize();
            return settings;
          },
        ),
      ],
      child: const ContactFixerApp(),
    ),
  );
}

class ContactFixerApp extends StatelessWidget {
  const ContactFixerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contact Fixer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFE0E5EC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF), // Accent highlight
          surface: const Color(0xFFE0E5EC),
          primary: const Color(0xFF3D4852), // Text color
          secondary: const Color(0xFF6B7280), // Muted text
          background: const Color(0xFFE0E5EC),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: TextTheme(
          displayLarge: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF3D4852),
            letterSpacing: -1.0,
          ),
          headlineLarge: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3D4852),
            letterSpacing: -0.5,
          ),
          titleLarge: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3D4852),
          ),
          bodyLarge: GoogleFonts.dmSans(
            fontSize: 16,
            color: const Color(0xFF3D4852),
          ),
          bodyMedium: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFF3D4852),
          ),
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
