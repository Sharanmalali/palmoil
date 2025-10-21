import 'package:atma_farm_app/screens/onboarding_session.dart';
import 'package:flutter/material.dart';
// Importing the Firebase Authentication package
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Instance of FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _otpSent = false;
  // A loading state to give feedback to the user
  bool _isLoading = false;
  // This will store the verification ID from Firebase
  String? _verificationId;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Function to navigate after successful login
  void _navigateToOnboarding() {
    // Using pushAndRemoveUntil to prevent the user from going back to the auth screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      (route) => false,
    );
  }

  // Function to send the OTP
  Future<void> _sendOtp() async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: '+91${_phoneController.text}',
      // Callback for when verification is complete (e.g., auto-retrieval)
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        if (mounted) {
          _navigateToOnboarding();
        }
      },
      // Callback for when verification fails
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send code: ${e.message}')),
          );
        }
      },
      // Callback for when the code has been sent to the device
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _otpSent = true;
            _verificationId = verificationId; // Store the verification ID
          });
        }
      },
      // Callback for when auto-retrieval times out
      codeAutoRetrievalTimeout: (String verificationId) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
          });
        }
      },
    );
  }

  // Function to verify the OTP
  Future<void> _verifyOtp() async {
    if (_verificationId == null || _otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a PhoneAuthCredential with the code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );

      // Sign the user in (or link) with the credential
      await _auth.signInWithCredential(credential);

      // On successful verification, navigate to the next screen
       if (mounted) {
          _navigateToOnboarding();
        }

    } on FirebaseAuthException catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in: ${e.message}')),
        );
       }
    } finally {
      // Check if the widget is still in the tree before calling setState
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register / रजिस्टर करें'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_otpSent)
                _buildPhoneInputView(context)
              else
                _buildOtpInputView(context),
              
              // Show a loading indicator when processing
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for entering the phone number
  Widget _buildPhoneInputView(BuildContext context) {
    return Column(
      children: [
        Text(
          'Enter your mobile number',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We will send you a confirmation code.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: InputDecoration(
            labelText: '10-digit mobile number',
            prefixText: '+91 ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          enabled: !_isLoading, // Disable field when loading
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: const Text('Send Confirmation Code'),
        ),
      ],
    );
  }

  // Widget for entering the OTP
  Widget _buildOtpInputView(BuildContext context) {
    return Column(
      children: [
        Text(
          'Enter the code we sent to',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        Text(
          '+91 ${_phoneController.text}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 12),
          decoration: InputDecoration(
            labelText: '6-digit code',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          enabled: !_isLoading, // Disable field when loading
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          child: const Text('Verify & Continue'),
        ),
        TextButton(
          onPressed: _isLoading ? null : () {
            setState(() {
              _otpSent = false;
              _otpController.clear();
            });
          },
          child: const Text('Change mobile number'),
        )
      ],
    );
  }
}

