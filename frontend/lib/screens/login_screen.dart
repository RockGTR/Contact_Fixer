import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/neumorphic_container.dart';
import '../widgets/neumorphic_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container - Extruded
                NeumorphicContainer(
                  width: 120,
                  height: 120,
                  borderRadius: BorderRadius.circular(40),
                  child: Center(
                    child: Icon(
                      Icons.contacts_rounded,
                      size: 64,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // App Title
                Text(
                  'Contact Fixer',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Tagline
                Text(
                  'Standardize your phone numbers\neffortlessly',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 64),

                // Sign In Button - Neumorphic
                NeumorphicButton(
                  onTap: () {
                    Provider.of<AuthProvider>(context, listen: false).login();
                  },
                  width: double.infinity,
                  height: 64,
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://www.google.com/favicon.ico',
                        height: 24,
                        width: 24,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.login,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Sign in with Google',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Bottom info
                Text(
                  'Your contacts stay private and secure',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),

                // Error message
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.errorMessage == null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: NeumorphicContainer(
                        padding: const EdgeInsets.all(16),
                        borderRadius: BorderRadius.circular(16),
                        // Light red simulation for error state if desired, or keep neutral
                        // For now keeping neutral with red text
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red[400],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                auth.errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[400],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
