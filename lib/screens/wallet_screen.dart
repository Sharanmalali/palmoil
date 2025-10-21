import 'package:flutter/material.dart';
import 'package:atma_farm_app/models/subsidy_application_model.dart';
import 'package:atma_farm_app/models/subsidy_scheme_model.dart';
import 'package:atma_farm_app/services/wallet_service.dart';
import 'package:atma_farm_app/screens/verification_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<Map<String, dynamic>> _walletDataFuture;
  final WalletService _walletService = WalletService();

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  void _loadWalletData() {
    _walletDataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final schemes = await _walletService.getAvailableSchemes();
    final applications = await _walletService.getUserApplications();
    return {'schemes': schemes, 'applications': applications};
  }

  void _refreshData() {
    setState(() {
      _loadWalletData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _walletDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data found.'));
          }

          final List<SubsidyScheme> schemes = snapshot.data!['schemes'];
          final List<SubsidyApplication> applications = snapshot.data!['applications'];

          return RefreshIndicator(
            onRefresh: () {
              _refreshData();
              return _walletDataFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionHeader('My Applications', FontAwesomeIcons.fileLines),
                const SizedBox(height: 12),
                applications.isEmpty
                    ? const _EmptyStateCard(message: 'You have not applied for any schemes yet.')
                    : Column(children: applications.map((app) => ApplicationStatusCard(application: app, onVerified: _refreshData)).toList()),

                const SizedBox(height: 32),

                _buildSectionHeader('Available Schemes', FontAwesomeIcons.handHoldingDollar),
                const SizedBox(height: 12),
                schemes.isEmpty
                    ? const _EmptyStateCard(message: 'No schemes are currently available. Check back later.')
                    : Column(children: schemes.map((scheme) => SchemeCard(scheme: scheme, existingApplications: applications, onApplied: _refreshData)).toList()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        FaIcon(icon, color: Colors.green.shade700, size: 20),
        const SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class SchemeCard extends StatefulWidget {
  final SubsidyScheme scheme;
  final List<SubsidyApplication> existingApplications;
  final VoidCallback onApplied;

  const SchemeCard({
    super.key, 
    required this.scheme,
    required this.existingApplications,
    required this.onApplied,
  });

  @override
  State<SchemeCard> createState() => _SchemeCardState();
}

class _SchemeCardState extends State<SchemeCard> {
  bool _isLoading = false;

  Future<void> _apply() async {
    setState(() => _isLoading = true);
    try {
      await WalletService().applyForScheme(widget.scheme);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully applied for ${widget.scheme.name}'), backgroundColor: Colors.green),
        );
      }
      widget.onApplied();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasApplied = widget.existingApplications.any((app) => app.schemeName == widget.scheme.name);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.scheme.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.scheme.description, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: hasApplied || _isLoading ? null : _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasApplied ? Colors.grey : Colors.green.shade700
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(hasApplied ? 'Applied' : 'Apply Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ApplicationStatusCard extends StatelessWidget {
  final SubsidyApplication application;
  final VoidCallback onVerified;

  const ApplicationStatusCard({super.key, required this.application, required this.onVerified});

  @override
  Widget build(BuildContext context) {
    final bool needsVerification = application.status == ApplicationStatus.applied;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(application.schemeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Applied on: ${DateFormat('dd MMMM yyyy').format(application.appliedAt.toDate())}'),
            const Divider(height: 24),
            _buildStatusTracker(application.status),
            if (needsVerification) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Submit Proof'),
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => VerificationScreen(applicationId: application.id),
                      ),
                    );
                    if (result == true) {
                      onVerified();
                    }
                  },
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTracker(ApplicationStatus currentStatus) {
    final statusText = currentStatus.name.replaceAll('_', ' ').toUpperCase();
    final statusColor = _getStatusColor(currentStatus);

    return Row(
      children: [
        Icon(Icons.check_circle, color: statusColor),
        const SizedBox(width: 8),
        Text(
          'Status: $statusText',
          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
        ),
      ],
    );
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.approved:
      case ApplicationStatus.paid:
        return Colors.green.shade700;
      case ApplicationStatus.rejected:
        return Colors.red;
      case ApplicationStatus.pending_verification:
      case ApplicationStatus.field_verified:
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String message;
  const _EmptyStateCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}

