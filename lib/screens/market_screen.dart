import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:atma_farm_app/models/farm_model.dart';
import 'package:atma_farm_app/models/ffb_log_model.dart';
import 'package:atma_farm_app/services/market_service.dart';
import 'package:atma_farm_app/screens/schedule_pickup_screen.dart';
import 'package:intl/intl.dart';

class MarketScreen extends StatefulWidget {
  final Farm farm; // We need the farm context for new pickups
  const MarketScreen({super.key, required this.farm});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  late Future<List<FfbLog>> _pickupsFuture;

  @override
  void initState() {
    super.initState();
    _loadPickups();
  }

  void _loadPickups() {
    _pickupsFuture = MarketService().getUserPickups();
  }

  void _refreshPickups() {
    setState(() {
      _loadPickups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          _refreshPickups();
          return _pickupsFuture;
        },
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // --- Schedule Button Section ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ready to sell your Fresh Fruit Bunches?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.green.shade900),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.calendarCheck, size: 18),
                    label: const Text('Schedule a New Pickup'),
                    onPressed: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (context) => SchedulePickupScreen(farmId: widget.farm.id),
                        ),
                      );
                      if (result == true) {
                        _refreshPickups();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // --- My Pickups Section ---
            Text(
              'My Pickup Requests',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            FutureBuilder<List<FfbLog>>(
              future: _pickupsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text('You have no pending pickup requests.'),
                    ),
                  );
                }

                final pickups = snapshot.data!;
                return Column(
                  children: pickups.map((pickup) => PickupStatusCard(pickup: pickup)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PickupStatusCard extends StatelessWidget {
  final FfbLog pickup;
  const PickupStatusCard({super.key, required this.pickup});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request - ${DateFormat('dd MMMM yyyy').format(pickup.requestedAt.toDate())}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Estimated Quantity: ${pickup.estimatedQuantityKg.round()} kg'),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.check_circle, color: _getStatusColor(pickup.status)),
                const SizedBox(width: 8),
                Text(
                  'Status: ${pickup.status.name.toUpperCase()}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(pickup.status)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(PickupStatus status) {
    switch (status) {
      case PickupStatus.completed:
        return Colors.green.shade700;
      case PickupStatus.scheduled:
        return Colors.blue.shade700;
      case PickupStatus.disputed:
        return Colors.red.shade700;
      default: // requested
        return Colors.orange.shade700;
    }
  }
}

