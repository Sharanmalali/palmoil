import 'package:flutter/material.dart';
import 'package:atma_farm_app/screens/auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                // ** THE CHANGE IS HERE **
                // The placeholder Icon is replaced with your actual logo.
                Image.asset(
                  'assets/images/logo.png', // The path we defined in pubspec.yaml
                  height: 120, // You can adjust the size as needed
                  errorBuilder: (context, error, stackTrace) {
                    // This will show a placeholder if the logo fails to load
                    return const Icon(
                      Icons.eco,
                      size: 100,
                      color: Colors.grey,
                    );
                  },
                ),
                const SizedBox(height: 24),
                
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
                
                Text(
                  'Your Partner in Oil Palm Cultivation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 64),
                
                ElevatedButton(
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

