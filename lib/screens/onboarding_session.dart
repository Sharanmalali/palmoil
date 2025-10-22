import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:atma_farm_app/screens/farm_pinpoint_screen.dart';
import 'package:speech_to_text/speech_to_text.dart'; // Add STT
import 'package:permission_handler/permission_handler.dart'; // Add Permissions
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Add FontAwesome

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedLanguage; // Example: 'en', 'hi', 'ta' etc.
  bool _isLoading = false;

  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  final Map<String, String> _supportedLanguages = {
    'English': 'en',
    'हिन्दी': 'hi', // Hindi
    // Add more languages as needed
    'தமிழ்': 'ta', // Tamil
  };

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
          onError: (error) => print('Onboarding STT Error: ${error.errorMsg}'),
          onStatus: (status) {
            print('Onboarding STT Status: $status');
            if (mounted) setState(() => _isListening = _speechToText.isListening);
          },
        );
      } catch (e) {
        print("Error initializing SpeechToText on Onboarding: $e");
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
    _showSnackbar('Listening...');

    _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          _handleVoiceCommand(result.recognizedWords);
          if (mounted) setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 10),
      localeId: "en_IN", // Consider dynamic locale based on selection later
    ).catchError((error) {
       print("Error during onboarding listen: $error");
       if(mounted) setState(() => _isListening = false);
    });
  }

   // Stop listening explicitly
  void _stopListening() {
    if (!_isListening) return;
    _speechToText.stop();
    setState(() => _isListening = false);
  }

  // Process voice commands specific to this screen
  void _handleVoiceCommand(String command) {
    final lowerCaseCommand = command.toLowerCase().trim();
    print("Onboarding Command: $lowerCaseCommand");

    if (lowerCaseCommand.startsWith('my name is')) {
      // Extract name (simple extraction, might need improvement)
      String name = lowerCaseCommand.replaceFirst('my name is', '').trim();
      // Capitalize first letter of each word
      name = name.split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');

      if (name.isNotEmpty) {
        setState(() { _nameController.text = name; });
         _showSnackbar('Name set to "$name".');
      } else {
         _showSnackbar('Could not understand the name.');
      }
    } else if (lowerCaseCommand.startsWith('select')) {
      String lang = lowerCaseCommand.replaceFirst('select', '').trim();
      // Try to match spoken language to supported languages (case-insensitive)
      String? matchedLangCode;
      String? matchedLangName;
      for (var entry in _supportedLanguages.entries) {
        // Match against key (display name) or value (code)
        if (lang == entry.key.toLowerCase() || lang == entry.value.toLowerCase()) {
          matchedLangCode = entry.value;
          matchedLangName = entry.key;
          break;
        }
      }
       if (matchedLangCode != null) {
         setState(() { _selectedLanguage = matchedLangCode; });
         _showSnackbar('Language set to $matchedLangName.');
       } else {
         _showSnackbar('Could not understand or language not supported: "$lang"');
       }
    } else if (lowerCaseCommand.contains('continue') || lowerCaseCommand.contains('next') || lowerCaseCommand.contains('save')) {
        _saveProfile(); // Attempt to save if command sounds like proceed
    }
     else {
      _showSnackbar('Command not understood.');
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedLanguage == null) {
      _showSnackbar('Please enter your name and select a language.');
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackbar('Authentication error. Please restart the app.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'phone': user.phoneNumber,
        'name': name,
        'language': _selectedLanguage,
        'role': 'farmer', // Default role
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Navigate using pushReplacement to prevent going back to onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const FarmPinpointScreen()),
      );
    } catch (e) {
      _showSnackbar('Failed to save profile: ${e.toString()}');
    } finally {
      // Ensure isLoading is set to false even if navigation happens quickly
      // or if there's an error before navigation. Check if still mounted.
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome! Let\'s get started.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              hint: const Text('Select Preferred Language'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: _supportedLanguages.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.value,
                  child: Text(entry.key), // Display the readable name
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLanguage = newValue;
                });
              },
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save and Continue'),
            ),
             const SizedBox(height: 32),
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
    );
  }

   @override
  void dispose() {
    _nameController.dispose();
    _speechToText.cancel();
    super.dispose();
  }
}

