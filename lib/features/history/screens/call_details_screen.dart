import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../utils/call_type_label.dart';
import '../utils/format_call_time.dart';

// Temporary hardcoded flag — will be replaced by the real Developer Mode
// toggle once Settings is built. Swap this to read from settings later.
const bool devMode = true;

class CallDetailScreen extends StatelessWidget {
  final Call call;

  const CallDetailScreen({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    final displayName = call.name?.isNotEmpty == true
        ? call.name!
        : (call.number ?? 'Unknown');

    return Scaffold(
      appBar: AppBar(title: const Text('Call Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 4),
            if (call.number != null) Text(call.number!),
            const SizedBox(height: 16),

            _DetailRow(label: 'Type', value: callTypeLabel(call.type)),
            _DetailRow(label: 'Duration', value: '${call.duration} seconds'),
            _DetailRow(label: 'Time', value: formatCallTime(call.timestamp)),

            if (devMode) ...[
              const Divider(height: 32),
              const Text(
                'Developer Info',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              _DetailRow(label: 'Row ID', value: call.id.toString()),
              _DetailRow(label: 'Raw type code', value: call.type.toString()),
              _DetailRow(
                label: 'Raw timestamp (epoch ms)',
                value: call.timestamp.toString(),
              ),
              _DetailRow(
                label: 'Removed from device',
                value: call.removedFromDevice.toString(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
