import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:atma_farm_app/screens/main_screen.dart';
import 'package:intl/intl.dart';
import 'package:atma_farm_app/models/farm_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all the details.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save details: $e')));
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Plantation Date ---
            _buildSectionHeader('When did you plant your oil palms?'),
            const SizedBox(height: 16),
            Container(
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
            IconSelector(
              options: const {
                'Borewell': FontAwesomeIcons.boreHole,
                'Canal': FontAwesomeIcons.water,
                'Rainfed': FontAwesomeIcons.cloudRain,
              },
              selectedValue: _selectedWaterSource,
              onSelected: (value) => setState(() => _selectedWaterSource = value),
            ),
            const SizedBox(height: 32),

            // --- Soil Type ---
            _buildSectionHeader('What is your soil like?'),
            const SizedBox(height: 16),
            IconSelector(
              options: const {
                'Red Loam': FontAwesomeIcons.solidCircle,
                'Black Cotton': FontAwesomeIcons.solidCircle,
                'Alluvial': FontAwesomeIcons.solidCircle,
              },
              optionColors: const {
                 'Red Loam': Colors.redAccent,
                 'Black Cotton': Colors.black87,
                 'Alluvial': Colors.brown,
              },
              selectedValue: _selectedSoilType,
              onSelected: (value) => setState(() => _selectedSoilType = value),
            ),
            const SizedBox(height: 48),

            // --- Save Button ---
            ElevatedButton(
              onPressed: _isLoading ? null : _saveFarmDetails,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Finish Setup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}


// A reusable widget for selecting an option with an icon
class IconSelector extends StatelessWidget {
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

