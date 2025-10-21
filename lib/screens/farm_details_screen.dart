import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:atma_farm_app/screens/home_screen.dart';
import 'package:atma_farm_app/models/farm_model.dart'; // Import the new Farm model
import 'package:intl/intl.dart';

class FarmDetailsScreen extends StatefulWidget {
  final String farmId;

  const FarmDetailsScreen({super.key, required this.farmId});

  @override
  State<FarmDetailsScreen> createState() => _FarmDetailsScreenState();
}

class _FarmDetailsScreenState extends State<FarmDetailsScreen> {
  DateTime? _selectedDate;
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
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plantation date.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final farmRef = FirebaseFirestore.instance.collection('farms').doc(widget.farmId);
      
      // 1. Update the document with the plantationDate
      await farmRef.update({
        'plantationDate': Timestamp.fromDate(_selectedDate!),
      });

      // 2. NOW, fetch the complete and updated document
      final updatedFarmDoc = await farmRef.get();
      final farmData = Farm.fromFirestore(updatedFarmDoc);

      // 3. Navigate to HomeScreen, PASSING the complete farm object
      if(mounted){
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen(farm: farmData)), // Pass the data here
          (Route<dynamic> route) => false,
        );
      }

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save details: $e')));
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farm Details')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('When did you plant your oil palms?', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_selectedDate == null ? 'No date chosen' : DateFormat('dd MMMM yyyy').format(_selectedDate!), style: const TextStyle(fontSize: 16)),
                  TextButton.icon(icon: const Icon(Icons.calendar_today), label: const Text('Select Date'), onPressed: () => _selectDate(context)),
                ],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveFarmDetails,
              child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Finish Setup'),
            ),
          ],
        ),
      ),
    );
  }
}

