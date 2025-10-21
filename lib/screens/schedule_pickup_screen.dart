import 'package:flutter/material.dart';
import 'package:atma_farm_app/services/market_service.dart';

class SchedulePickupScreen extends StatefulWidget {
  final String farmId;
  const SchedulePickupScreen({super.key, required this.farmId});

  @override
  State<SchedulePickupScreen> createState() => _SchedulePickupScreenState();
}

class _SchedulePickupScreenState extends State<SchedulePickupScreen> {
  double _estimatedQuantity = 100.0; // Default value
  bool _isLoading = false;

  Future<void> _submitRequest() async {
    setState(() => _isLoading = true);
    try {
      await MarketService().requestPickup(_estimatedQuantity, widget.farmId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup request submitted successfully!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true); // Pop with 'true' to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule FFB Pickup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Estimate the quantity of FFB you want to sell.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            Text(
              '${_estimatedQuantity.toStringAsFixed(0)} kg',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: _estimatedQuantity,
              min: 50,
              max: 2000,
              divisions: 195, // (2000-50)/10
              label: '${_estimatedQuantity.round()} kg',
              onChanged: (double value) {
                setState(() {
                  _estimatedQuantity = value;
                });
              },
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitRequest,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Confirm Pickup Request'),
            ),
          ],
        ),
      ),
    );
  }
}
