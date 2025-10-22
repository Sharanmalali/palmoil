import 'package:flutter/material.dart';
import 'package:atma_farm_app/screens/auth_screen.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  // Initialize speech recognition
  Future<void> _initSpeech() async {
     bool micPermissionGranted = await Permission.microphone.request().isGranted;
     bool speechAvailable = false;
     if (micPermissionGranted) {
      try {
        speechAvailable = await _speechToText.initialize(
          onError: (error) => print('Welcome STT Error: ${error.errorMsg}'),
          onStatus: (status) {
            print('Welcome STT Status: $status');
            if (mounted) setState(() => _isListening = _speechToText.isListening);
          },
        );
      } catch (e) {
        print("Error initializing SpeechToText on Welcome: $e");
      }
     }
     if (mounted) {
       setState(() { _speechEnabled = speechAvailable; });
     }
  }

  // Start listening for a command
  void _startListening() {
    if (!_speechEnabled) {
      _showSnackbar('Speech recognition not available.');
      return;
    }
    if (_isListening) return;

    setState(() => _isListening = true);
    _showSnackbar('Listening for command...');

    _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          _handleVoiceCommand(result.recognizedWords);
          if (mounted) setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 5), // Listen for a short command
      localeId: "en_IN",
    ).catchError((error) {
       print("Error during welcome listen: $error");
       if(mounted) setState(() => _isListening = false);
    });
  }

  // Stop listening explicitly
  void _stopListening() {
    if (!_isListening) return;
    _speechToText.stop();
    setState(() => _isListening = false);
  }

  // Process the command
  void _handleVoiceCommand(String command) {
    final lowerCaseCommand = command.toLowerCase().trim();
    print("Welcome Command: $lowerCaseCommand");

    if (lowerCaseCommand.contains('start') || lowerCaseCommand.contains('register') || lowerCaseCommand.contains('registration')) {
      _navigateToAuthScreen();
    } else {
      _showSnackbar('Command not understood: "$command"');
    }
  }

  // Navigate function
  void _navigateToAuthScreen() {
     // Ensure we're not rebuilding during a build phase
     WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted) {
            Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AuthScreen(),
            ),
          );
        }
     });
  }

  // Helper for snackbars
  void _showSnackbar(String message) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ Colors.green.shade50, Colors.green.shade200 ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon( Icons.eco, size: 100, color: Colors.grey );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Atma-Palm',
                  textAlign: TextAlign.center,
                  style: TextStyle( fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green.shade900 ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Partner in Oil Palm Cultivation',
                  textAlign: TextAlign.center,
                  style: TextStyle( fontSize: 16, color: Colors.green.shade700 ),
                ),
                const SizedBox(height: 64),
                ElevatedButton(
                  onPressed: _navigateToAuthScreen, // Use the navigation function
                  child: const Text('Start Registration'),
                ),
                const SizedBox(height: 24), // Space for the mic button
                // Microphone Button
                IconButton(
                  icon: FaIcon(_isListening ? FontAwesomeIcons.stop : FontAwesomeIcons.microphone),
                  iconSize: 40,
                  color: _isListening ? Colors.red : Colors.green.shade700,
                  tooltip: 'Tap to speak command',
                  onPressed: _speechEnabled ? (_isListening ? _stopListening : _startListening) : null,
                ),
                if (_isListening) // Visual indicator
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('Listening...', textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

   @override
  void dispose() {
    _speechToText.cancel();
    super.dispose();
  }
}

