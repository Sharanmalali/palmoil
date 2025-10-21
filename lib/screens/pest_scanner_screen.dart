import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PestScannerScreen extends StatefulWidget {
  const PestScannerScreen({super.key});

  @override
  State<PestScannerScreen> createState() => _PestScannerScreenState();
}

class _PestScannerScreenState extends State<PestScannerScreen> {
  File? _selectedImage;
  String? _analysisResult;
  String? _solution;
  double? _confidence;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Function to simulate AI analysis
  Future<void> _analyzeImage(File image) async {
    setState(() {
      _isLoading = true;
      _analysisResult = null;
      _solution = null;
      _confidence = null;
    });

    // Simulate a network delay for the AI model
    await Future.delayed(const Duration(seconds: 3));

    // In a real app, you would send the image to a backend with a ML model.
    // Here, we are just returning a hardcoded "dummy" result.
    setState(() {
      _analysisResult = "Ganoderma Butt Rot";
      _solution = "This disease is caused by a fungus. It is recommended to remove and destroy the infected palm. Apply fungicide to surrounding palms as a preventive measure.";
      _confidence = 0.92; // 92% confidence
      _isLoading = false;
    });
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        setState(() {
          _selectedImage = imageFile;
        });
        _analyzeImage(imageFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Pest & Disease Scanner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              // Image display area
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImage == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_search, size: 60, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Take or select a photo of a leaf', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Analysis result section
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyzing image...', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),

              if (_analysisResult != null && !_isLoading)
                _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  // A widget to display the result in a nice card
  Widget _buildResultCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.microscope, color: Colors.blueAccent),
                const SizedBox(width: 12),
                const Text('Analysis Result', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  '${(_confidence! * 100).toStringAsFixed(0)}% Match',
                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              _analysisResult!,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recommended Action:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _solution!,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
