import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:atma_farm_app/screens/main_screen.dart';
import 'package:intl/intl.dart';
import 'package:atma_farm_app/models/farm_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart'; // Add STT
import 'package:permission_handler/permission_handler.dart'; // Add Permissions

class FarmDetailsScreen extends StatefulWidget {
  final String farmId;

  const FarmDetailsScreen({super.key, required this.farmId});

  @override
  State<FarmDetailsScreen> createState() => _FarmDetailsScreenState();
}

class _FarmDetailsScreenState extends State<FarmDetailsScreen> {
  DateTime? _selectedDate;
  String? _selectedWaterSource;
  String? _selectedSoilType;
  bool _isLoading = false;

  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  // Define options for easier voice matching
  final Map<String, IconData> _waterSourceOptions = const {
    'Borewell': FontAwesomeIcons.boreHole,
    'Canal': FontAwesomeIcons.water,
    'Rainfed': FontAwesomeIcons.cloudRain,
  };
   final Map<String, IconData> _soilTypeOptions = const {
    'Red Loam': FontAwesomeIcons.solidCircle,
    'Black Cotton': FontAwesomeIcons.solidCircle,
    'Alluvial': FontAwesomeIcons.solidCircle,
  };
   final Map<String, Color> _soilTypeColors = const {
     'Red Loam': Colors.redAccent,
     'Black Cotton': Colors.black87,
     'Alluvial': Colors.brown,
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
          onError: (error) => print('FarmDetails STT Error: ${error.errorMsg}'),
          onStatus: (status) {
            print('FarmDetails STT Status: $status');
            if (mounted) setState(() => _isListening = _speechToText.isListening);
          },
        );
      } catch (e) {
        print("Error initializing SpeechToText on FarmDetails: $e");
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
      localeId: "en_IN",
    ).catchError((error) {
       print("Error during farm details listen: $error");
       if(mounted) setState(() => _isListening = false);
    });
  }

   // Stop listening explicitly
  void _stopListening() {
    if (!_isListening) return;
    _speechToText.stop();
    setState(() => _isListening = false);
  }

  // Process voice commands for this screen
  void _handleVoiceCommand(String command) {
    final lowerCaseCommand = command.toLowerCase().trim();
    print("Farm Details Command: $lowerCaseCommand");
    String? matchedValue;

    // Check water sources
    for(var key in _waterSourceOptions.keys) {
      if(lowerCaseCommand.contains(key.toLowerCase())) {
        matchedValue = key;
        setState(() => _selectedWaterSource = matchedValue);
        _showSnackbar('Water source set to $matchedValue.');
        return; // Command processed
      }
    }

    // Check soil types
    for(var key in _soilTypeOptions.keys) {
      // Handle multi-word soil types like "red loam", also match "redloam"
      if(lowerCaseCommand.contains(key.toLowerCase()) || lowerCaseCommand.contains(key.toLowerCase().replaceAll(' ', ''))) {
        matchedValue = key;
        setState(() => _selectedSoilType = matchedValue);
        _showSnackbar('Soil type set to $matchedValue.');
        return; // Command processed
      }
    }

    // Check for finish/save command
    if(lowerCaseCommand.contains('finish') || lowerCaseCommand.contains('save') || lowerCaseCommand.contains('done') || lowerCaseCommand.contains('continue')) {
       _saveFarmDetails();
       return; // Command processed
    }

    // If no match
    _showSnackbar('Command not understood.');
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveFarmDetails() async {
    if (_selectedDate == null || _selectedWaterSource == null || _selectedSoilType == null) {
      _showSnackbar('Please fill in all the details.');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final farmRef = FirebaseFirestore.instance.collection('farms').doc(widget.farmId);
      
      await farmRef.update({
        'plantationDate': Timestamp.fromDate(_selectedDate!),
        'waterSource': _selectedWaterSource,
        'soilType': _selectedSoilType,
      });

      final updatedFarmDoc = await farmRef.get();
      final farm = Farm.fromFirestore(updatedFarmDoc);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainScreen(farm: farm)),
        (Route<dynamic> route) => false,
      );

    } catch (e) {
       _showSnackbar('Failed to save details: $e');
        // Keep loading indicator false on error if mounted
        if(mounted) setState(() => _isLoading = false);
    } 
    // No finally block needed here, isLoading handled in try/catch for mounted check
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
        title: const Text('Farm Details'),
      ),
      body: SingleChildScrollView( // Added ScrollView
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Plantation Date ---
            _buildSectionHeader('When did you plant your oil palms?'),
            const SizedBox(height: 16),
            Container( // Date Picker Row
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate == null ? 'No date chosen' : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Select Date'),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Water Source ---
            _buildSectionHeader('What is your primary water source?'),
            const SizedBox(height: 16),
            IconSelector( // Water Source Selector
              options: _waterSourceOptions,
              selectedValue: _selectedWaterSource,
              onSelected: (value) => setState(() => _selectedWaterSource = value),
            ),
            const SizedBox(height: 32),

            // --- Soil Type ---
            _buildSectionHeader('What is your soil like?'),
            const SizedBox(height: 16),
            IconSelector( // Soil Type Selector
              options: _soilTypeOptions,
              optionColors: _soilTypeColors,
              selectedValue: _selectedSoilType,
              onSelected: (value) => setState(() => _selectedSoilType = value),
            ),
            const SizedBox(height: 48),

            // --- Save Button ---
            ElevatedButton( // Save Button
              onPressed: _isLoading ? null : _saveFarmDetails,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Finish Setup'),
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

  Widget _buildSectionHeader(String title) { // Section Header Helper
     return Text(
      title,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

   @override
  void dispose() {
    _speechToText.cancel();
    super.dispose();
  }
}


// A reusable widget for selecting an option with an icon
class IconSelector extends StatelessWidget { // Icon Selector Helper Widget
   final Map<String, IconData> options;
  final Map<String, Color>? optionColors;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  const IconSelector({
    super.key,
    required this.options,
    this.optionColors,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: options.keys.map((key) {
        final isSelected = selectedValue == key;
        return GestureDetector(
          onTap: () => onSelected(key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                FaIcon(
                  options[key],
                  color: optionColors?[key] ?? (isSelected ? Colors.green.shade800 : Colors.black54),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  key,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.green.shade900 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

