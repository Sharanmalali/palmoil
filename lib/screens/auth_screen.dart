import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:atma_farm_app/screens/onboarding_session.dart';
import 'package:speech_to_text/speech_to_text.dart'; // Add STT
import 'package:permission_handler/permission_handler.dart'; // Add Permissions
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Add FontAwesome

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String? _verificationId;
  bool _isLoading = false;
  bool _codeSent = false;

  // Speech to Text
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
          onError: (error) => print('Auth STT Error: ${error.errorMsg}'),
          onStatus: (status) {
            print('Auth STT Status: $status');
            if (mounted) setState(() => _isListening = _speechToText.isListening);
          },
        );
      } catch (e) {
        print("Error initializing SpeechToText on Auth: $e");
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
        } else {
           // Update text field partially while listening (optional but helpful)
           // You might need more complex logic to handle partial number inputs
           // For simplicity, we'll only process final results for now
        }
      },
      listenFor: const Duration(seconds: 10),
      localeId: "en_IN",
    ).catchError((error) {
       print("Error during auth listen: $error");
       if(mounted) setState(() => _isListening = false);
    });
  }

  // Stop listening explicitly
  void _stopListening() {
    if (!_isListening) return;
    _speechToText.stop();
    setState(() => _isListening = false);
  }

  // Process voice commands specific to the Auth screen
  void _handleVoiceCommand(String command) {
    final lowerCaseCommand = command.toLowerCase().trim();
    print("Auth Command: $lowerCaseCommand");

    if (!_codeSent) { // Handling commands for phone number input
      if (lowerCaseCommand.startsWith('my number is')) {
        String? number = _extractNumber(lowerCaseCommand);
        if (number != null) {
          setState(() { _phoneController.text = number; });
          _showSnackbar('Phone number set.');
        } else {
          _showSnackbar('Could not understand the number.');
        }
      } else if (lowerCaseCommand.contains('send') && lowerCaseCommand.contains('code')) {
        _sendOtp();
      } else {
         _showSnackbar('Command not understood for phone input.');
      }
    } else { // Handling commands for OTP input
       if (lowerCaseCommand.startsWith('my code is') || lowerCaseCommand.startsWith('the code is')) {
         String? code = _extractNumber(lowerCaseCommand, allowSpaces: false); // OTPs usually don't have spaces
        if (code != null && code.length == 6) { // Basic OTP validation
          setState(() { _otpController.text = code; });
          _showSnackbar('OTP code set.');
        } else {
          _showSnackbar('Could not understand the 6-digit code.');
        }
       } else if (lowerCaseCommand.contains('verify') || lowerCaseCommand.contains('confirm')) {
         _verifyOtp();
       } else {
         _showSnackbar('Command not understood for OTP input.');
       }
    }
  }

  // Helper to extract numbers (spoken or digits) from a string
  String? _extractNumber(String command, {bool allowSpaces = true}) {
      // Basic extraction - removes non-digits (and optionally spaces)
      String digits = command.replaceAll(RegExp(r'[^0-9' + (allowSpaces ? ' ' : '') + r']'), '');
      digits = digits.replaceAll(' ', ''); // Remove spaces if needed for OTP
      
      // Add simple spoken number conversion (can be expanded)
      // This is very basic and needs improvement for real-world use
      command = command.replaceAll('zero', '0').replaceAll('one', '1').replaceAll('two', '2')
                       .replaceAll('three', '3').replaceAll('four', '4').replaceAll('five', '5')
                       .replaceAll('six', '6').replaceAll('seven', '7').replaceAll('eight', '8')
                       .replaceAll('nine', '9');
                       
      String spokenDigits = command.replaceAll(RegExp(r'[^0-9]'), '');

      // Prioritize digit extraction, fall back to basic spoken conversion
      if (digits.isNotEmpty) return digits;
      if (spokenDigits.isNotEmpty) return spokenDigits;
      
      return null;
  }


  Future<void> _sendOtp() async {
    if (_isLoading || _phoneController.text.length < 10) return;
    setState(() => _isLoading = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: '+91${_phoneController.text}', // Assuming Indian numbers
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval or instant verification (less common)
        await _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        _showSnackbar('Verification Failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isLoading = false;
          _codeSent = true; // Move to OTP screen state
        });
        _showSnackbar('OTP Sent successfully.');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Called when auto-retrieval times out
        setState(() {
          _verificationId = verificationId;
          // Don't set isLoading false here, wait for manual OTP
        });
      },
      timeout: const Duration(seconds: 60),
    );
  }

  Future<void> _verifyOtp() async {
    if (_isLoading || _verificationId == null || _otpController.text.length != 6) return;
    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('OTP Verification Failed: ${e.message}');
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      await _auth.signInWithCredential(credential);
      // Navigate on successful sign-in
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Sign In Failed: ${e.message}');
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
        title: Text(_codeSent ? 'Enter OTP' : 'Register Phone'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_codeSent) ...[
              Text(
                'Enter your 10-digit mobile number to begin.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Confirmation Code'),
              ),
            ] else ...[
              Text(
                'Enter the 6-digit code sent to +91${_phoneController.text}.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'OTP Code',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify Code'),
              ),
              TextButton(
                 onPressed: _isLoading ? null : () => setState(() => _codeSent = false),
                 child: const Text('Change Number?'),
              )
            ],
            const SizedBox(height: 32),
            // Microphone Button for voice commands
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
    _phoneController.dispose();
    _otpController.dispose();
    _speechToText.cancel();
    super.dispose();
  }
}

