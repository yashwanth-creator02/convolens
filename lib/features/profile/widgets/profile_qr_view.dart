import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../models/profile_field_def.dart';
import '../screens/share_contact_screen.dart';
import '../utils/vcard_builder.dart';

class ProfileQrView extends StatelessWidget {
  final ShareQrType type;
  final Map<String, ProfileFieldEntry> fields;
  final Set<String>? customSelectedKeys;

  const ProfileQrView({
    super.key,
    required this.type,
    required this.fields,
    this.customSelectedKeys,
  });

  static const _personalSections = [
    'Basic',
    'Contact',
    'Address',
    'Additional',
  ];
  static const _workSections = ['Professional'];

  @override
  Widget build(BuildContext context) {
    final eligibleDefs = profileFieldDefs.where((def) {
      final entry = fields[def.key];
      final hasValue = entry?.value?.isNotEmpty == true;
      final isShared = entry?.shared ?? false;
      return hasValue && isShared;
    }).toList();

    List<ProfileFieldDef> includedDefs;
    if (type == ShareQrType.custom) {
      includedDefs = eligibleDefs
          .where((def) => customSelectedKeys?.contains(def.key) ?? false)
          .toList();
    } else if (type == ShareQrType.all) {
      includedDefs = eligibleDefs;
    } else if (type == ShareQrType.personal) {
      includedDefs = eligibleDefs
          .where((def) => _personalSections.contains(def.section))
          .toList();
    } else {
      includedDefs = eligibleDefs
          .where((def) => _workSections.contains(def.section))
          .toList();
    }

    if (includedDefs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No shareable fields match this category yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final values = {
      for (final def in includedDefs) def.key: fields[def.key]?.value ?? '',
    };

    final vcard = buildVCard(values);

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        GlassContainer(
          quality: GlassQuality.premium,
          useOwnLayer: true,
          padding: EdgeInsets.zero,
          shape: LiquidRoundedRectangle(borderRadius: 24.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: QrImageView(
              data: vcard,
              size: 180,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.circle,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Including: ${includedDefs.map((d) => d.label).join(', ')}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
