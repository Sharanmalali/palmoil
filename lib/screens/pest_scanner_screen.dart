import 'dart:io';
import 'dart:convert'; // Import for jsonDecode and base64Encode
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http; // Import the HTTP package

class PestScannerScreen extends StatefulWidget {
  const PestScannerScreen({super.key});

  @override
  State<PestScannerScreen> createState() => _PestScannerScreenState();
}

class _PestScannerScreenState extends State<PestScannerScreen> {
  // =======================================================================
  // ==  1. PASTE YOUR GOOGLE AI API KEY HERE                             ==
  // =======================================================================
  // Get your key from https://aistudio.google.com/
  
  final String _googleAiApiKey = 'AIzaSyBbX04liTbjF_ts-jSUli5BlmBd4VjmXdY';

  // =======================================================================

  File? _selectedImage;
  String? _analysisResult;
  String? _solution;
  double? _confidence;
  bool _isLoading = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  // This function now sends the image to the Gemini API
  Future<void> _analyzeImage(File image) async {
    setState(() {
      _isLoading = true;
      _analysisResult = null;
      _solution = null;
      _confidence = null;
      _errorMessage = null;
    });

    if (_googleAiApiKey == 'YOUR_GOOGLE_AI_API_KEY_GOES_HERE') {
      setState(() {
        _errorMessage = 'Please add your Google AI API key to pest_scanner_screen.dart';
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Read image and convert to base64
      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // 2. Define the prompt and the required JSON structure
      final textPrompt = """
      You are an agricultural expert specializing in oil palm diseases. 
      Analyze this image of an oil palm leaf and identify any diseases. 
      If the image is not an oil palm leaf or is unclear, set the disease to 'Unknown' and the solution to 'Image is unclear or not an oil palm leaf. Please try again with a clearer photo.'
      """;
      
      final schema = {
        "type": "OBJECT",
        "properties": {
          "disease": {"type": "STRING"},
          "confidence": {"type": "NUMBER"},
          "solution": {"type": "STRING"}
        },
        "required": ["disease", "confidence", "solution"]
      };

      // 3. Create the API payload
      final payload = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": textPrompt},
              {
                "inlineData": {
                  "mimeType": "image/jpeg", // We assume JPEG from the camera
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "responseMimeType": "application/json",
          "responseSchema": schema,
        }
      });

      // 4. Send the request to the Gemini API
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=$_googleAiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      // 5. Handle the response
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        
        // When using a schema, the JSON is in a string inside the 'text' part.
        final candidate = responseBody['candidates'][0];
        final jsonText = candidate['content']['parts'][0]['text'];
        final data = jsonDecode(jsonText);

        setState(() {
          _analysisResult = data['disease'];
          _solution = data['solution'];
          _confidence = (data['confidence'] as num).toDouble();
          _isLoading = false;
        });
      } else {
        // Handle API errors (e.g., billing not enabled, wrong API key)
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to analyze image: ${errorBody['error']['message']}');
      }
    } catch (e) {
      // Handle network or other errors
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Function to pick an image (no changes needed)
  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _selectedImage = null;
      _analysisResult = null;
      _solution = null;
      _confidence = null;
      _errorMessage = null;
    });

    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        setState(() {
          _selectedImage = imageFile;
        });
        await _analyzeImage(imageFile);
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
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                  ),
  
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
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

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 40),
                      const SizedBox(height: 16),
                      const Text('Analysis Failed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
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

  // Result card (no changes needed)
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

