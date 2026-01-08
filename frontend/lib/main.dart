import 'package:flutter/material.dart';
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
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
