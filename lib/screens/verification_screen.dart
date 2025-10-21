import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class VerificationScreen extends StatefulWidget {
  final String applicationId; // We need the ID of the application to update it

  const VerificationScreen({super.key, required this.applicationId});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  File? _imageFile;
  Position? _currentPosition;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePicture() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitProof() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo as proof.')),
      );
      return;
    }

    setState(() { _isSubmitting = true; });

    try {
      // 1. Get current GPS location
      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // 2. Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('verification_proofs')
          .child('${widget.applicationId}.jpg');
      
      await storageRef.putFile(_imageFile!);
      final imageUrl = await storageRef.getDownloadURL();

      // 3. Update the application document in Firestore
      await FirebaseFirestore.instance
          .collection('subsidy_applications')
          .doc(widget.applicationId)
          .update({
            'status': 'pending_verification',
            'verificationPhoto': {
              'url': imageUrl,
              'location': GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
            },
            'verifiedAt': FieldValue.serverTimestamp(),
          });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proof submitted successfully!'), backgroundColor: Colors.green),
      );
      
      // Go back to the wallet screen
      Navigator.of(context).pop(true); // Pop with a 'true' result to indicate success

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit proof: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if(mounted) setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Verification Proof'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Please capture a clear photo of your saplings or farm area for verification.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _imageFile == null
                  ? Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.camera_alt, size: 40),
                        label: const Text('Take Photo'),
                        onPressed: _takePicture,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    ),
            ),
            if (_imageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake Photo'),
                  onPressed: _takePicture,
                ),
              ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.paperPlane),
              label: const Text('Submit Proof'),
              onPressed: (_imageFile == null || _isSubmitting) ? null : _submitProof,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)
              ),
            ),
            if (_isSubmitting)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
