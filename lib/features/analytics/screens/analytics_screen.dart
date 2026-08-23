import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../contacts/models/contact_summary.dart';
import '../../contacts/screens/contact_detail_screen.dart';
import '../models/analytics_summary.dart';
import '../repository/analytics_repository.dart';

class AnalyticsScreen extends StatefulWidget {
  final AppDatabase db;

  const AnalyticsScreen({super.key, required this.db});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final AnalyticsRepository _repository;
  List<Contact> _deviceContacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = AnalyticsRepository(widget.db);
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      _deviceContacts = await FlutterContacts.getContacts(withProperties: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openContact(ContactSummary contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailScreen(
          normalizedNumber: contact.normalizedNumber,
          displayName: contact.displayName,
          displayNumber: contact.displayNumber,
          deviceContact: contact.deviceContact,
          db: widget.db,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<AnalyticsSummary>(
      stream: _repository.watchSummary(_deviceContacts),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _statCard('Calls', '${summary.totalCalls}'),
                const SizedBox(width: 12),
                _statCard('Contacts', '${summary.totalContacts}'),
                const SizedBox(width: 12),
                _statCard(
                  'Talk Time',
                  '${(summary.totalTalkSeconds / 60).round()}m',
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Calls — Last 14 Days',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildBarChart(summary),

            const SizedBox(height: 24),
            const Text(
              'Most Contacted',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (summary.mostContacted.isEmpty)
              const Text('No calls yet.', style: TextStyle(color: Colors.grey))
            else
              ...summary.mostContacted.map(
                (c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.displayName),
                  trailing: Text('${c.callCount} calls'),
                  onTap: () => _openContact(c),
                ),
              ),

            const SizedBox(height: 24),
            const Text(
              "Haven't Talked To In A While",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Contacts you have saved but rarely or never call',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (summary.silentContacts.isEmpty)
              const Text(
                "You're in touch with everyone!",
                style: TextStyle(color: Colors.grey),
              )
            else
              ...summary.silentContacts
                  .take(10)
                  .map(
                    (c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.displayName),
                      subtitle: Text(
                        c.lastCallAt == null
                            ? 'Never called'
                            : 'Last called ${_daysAgo(c.lastCallAt!)} days ago',
                      ),
                      onTap: () => _openContact(c),
                    ),
                  ),
          ],
        );
      },
    );
  }

  int _daysAgo(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(date).inDays;
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(AnalyticsSummary summary) {
    final maxValue = summary.callsPerDay.isEmpty
        ? 1
        : summary.callsPerDay.reduce((a, b) => a > b ? a : b).clamp(1, 999999);

    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(summary.callsPerDay.length, (index) {
          final value = summary.callsPerDay[index];
          final heightFraction = value / maxValue;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$value', style: const TextStyle(fontSize: 9)),
                  Container(
                    height: 60 * heightFraction,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary.dayLabels[index],
                    style: const TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
