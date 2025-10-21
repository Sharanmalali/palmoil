import 'package:atma_farm_app/screens/auth_screen.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Add a subtle gradient background for a better look
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade50,
              Colors.green.shade200,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Placeholder for the App Logo
                Icon(
                  Icons.eco, // Using a simple leaf icon for now
                  size: 100,
                  color: Colors.green.shade800,
                ),
                const SizedBox(height: 24),
                // App Name
                Text(
                  'Atma-Palm',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                // Tagline
                Text(
                  'Your Partner in Oil Palm Cultivation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 64),
                // Registration Button
                ElevatedButton(
                  // When pressed, navigate to the AuthScreen
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(),
                      ),
                    );
                  },
                  child: const Text('Start Registration'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
