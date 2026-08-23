import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/database/app_database.dart';
import '../models/profile_field_def.dart';
import '../utils/vcard_builder.dart';

enum ShareQrType { personal, work, all, custom }

const List<String> _personalSections = [
  'Basic',
  'Contact',
  'Address',
  'Additional',
];
const List<String> _workSections = ['Professional'];

class ShareContactScreen extends StatefulWidget {
  final AppDatabase db;
  final ShareQrType type;

  const ShareContactScreen({super.key, required this.db, required this.type});

  @override
  State<ShareContactScreen> createState() => _ShareContactScreenState();
}

class _ShareContactScreenState extends State<ShareContactScreen> {
  final Set<String> _customSelectedKeys = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titleFor(widget.type))),
      body: StreamBuilder<Map<String, ProfileFieldEntry>>(
        stream: widget.db.watchProfileFields(),
        builder: (context, snapshot) {
          final fields = snapshot.data ?? {};

          final eligibleDefs = profileFieldDefs.where((def) {
            final entry = fields[def.key];
            final hasValue = entry?.value?.isNotEmpty == true;
            final isShared = entry?.shared ?? false;
            return hasValue && isShared;
          }).toList();

          if (widget.type == ShareQrType.custom) {
            return _buildCustomPicker(context, eligibleDefs, fields);
          }

          final includedDefs = eligibleDefs.where((def) {
            if (widget.type == ShareQrType.all) return true;
            if (widget.type == ShareQrType.personal) {
              return _personalSections.contains(def.section);
            }
            return _workSections.contains(def.section);
          }).toList();

          return _buildQrView(context, includedDefs, fields);
        },
      ),
    );
  }

  String _titleFor(ShareQrType type) {
    switch (type) {
      case ShareQrType.personal:
        return 'Personal QR';
      case ShareQrType.work:
        return 'Work QR';
      case ShareQrType.all:
        return 'All QR';
      case ShareQrType.custom:
        return 'Custom QR';
    }
  }

  Widget _buildCustomPicker(
    BuildContext context,
    List<ProfileFieldDef> eligibleDefs,
    Map<String, ProfileFieldEntry> fields,
  ) {
    if (eligibleDefs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No shareable fields yet. Fill in details and turn on Share for at least one field in Edit Details.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: eligibleDefs.map((def) {
              return CheckboxListTile(
                title: Text(def.label),
                subtitle: Text(fields[def.key]!.value!),
                value: _customSelectedKeys.contains(def.key),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _customSelectedKeys.add(def.key);
                    } else {
                      _customSelectedKeys.remove(def.key);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _customSelectedKeys.isEmpty
                  ? null
                  : () {
                      final selectedDefs = eligibleDefs
                          .where((def) => _customSelectedKeys.contains(def.key))
                          .toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(title: const Text('Custom QR')),
                            body: _buildQrView(context, selectedDefs, fields),
                          ),
                        ),
                      );
                    },
              child: const Text('Generate QR'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrView(
    BuildContext context,
    List<ProfileFieldDef> includedDefs,
    Map<String, ProfileFieldEntry> fields,
  ) {
    if (includedDefs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No shareable fields match this category yet.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final values = {
      for (final def in includedDefs) def.key: fields[def.key]?.value ?? '',
    };

    final vcard = buildVCard(values);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: vcard, size: 240),
            const SizedBox(height: 16),
            Text(
              'Including: ${includedDefs.map((d) => d.label).join(', ')}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
