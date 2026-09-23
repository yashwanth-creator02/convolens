import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../models/profile_field_def.dart';

/// Shows all profile sections (Basic, Contact, Professional, Address,
/// Online, Additional) in a scrollable glass list.
///
/// Reached via the "Full Info" tile on the main Profile screen.
class ProfileFullInfoScreen extends StatefulWidget {
  final AppDatabase db;

  /// Pre-resolved fields map passed from the parent to avoid an extra DB
  /// listen. The screen also sets up its own stream so live edits are
  /// reflected without a pop-and-re-push.
  final Map<String, ProfileFieldEntry> fields;

  const ProfileFullInfoScreen({
    super.key,
    required this.db,
    required this.fields,
  });

  @override
  State<ProfileFullInfoScreen> createState() => _ProfileFullInfoScreenState();
}

class _ProfileFullInfoScreenState extends State<ProfileFullInfoScreen> {
  final _titleController = GlassLargeTitleController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4.5),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 13, color: scheme.primary),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildTileLeading(IconData icon, ColorScheme scheme) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 17, color: scheme.primary),
    );
  }

  IconData _iconForField(ProfileFieldDef def) {
    switch (def.type) {
      case FieldInputType.phone:
        return Icons.phone_outlined;
      case FieldInputType.email:
        return Icons.email_outlined;
      case FieldInputType.date:
        return Icons.cake_outlined;
      case FieldInputType.multiline:
        return Icons.notes_rounded;
      case FieldInputType.text:
        break;
    }
    switch (def.key) {
      case 'firstName':
      case 'middleName':
      case 'lastName':
      case 'displayName':
        return Icons.person_outline_rounded;
      case 'pronouns':
        return Icons.record_voice_over_outlined;
      case 'company':
        return Icons.business_outlined;
      case 'jobTitle':
        return Icons.work_outline_rounded;
      case 'department':
        return Icons.corporate_fare_rounded;
      case 'employeeId':
        return Icons.badge_outlined;
      case 'addressLine1':
      case 'addressLine2':
      case 'city':
      case 'state':
      case 'country':
      case 'postalCode':
        return Icons.location_on_outlined;
      case 'website':
        return Icons.language_rounded;
      case 'linkedin':
        return Icons.link_rounded;
      case 'github':
        return Icons.code_rounded;
      case 'instagram':
        return Icons.photo_camera_outlined;
      case 'twitter':
        return Icons.alternate_email_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  IconData _sectionIcon(String section) {
    switch (section) {
      case 'Basic':
        return Icons.person_outline_rounded;
      case 'Contact':
        return Icons.contact_phone_outlined;
      case 'Professional':
        return Icons.work_outline_rounded;
      case 'Address':
        return Icons.location_on_outlined;
      case 'Online':
        return Icons.language_rounded;
      case 'Additional':
        return Icons.notes_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Full Info'),
        largeTitleController: _titleController,
      ),
      body: StreamBuilder<Map<String, ProfileFieldEntry>>(
        stream: widget.db.watchProfileFields(),
        builder: (context, snapshot) {
          final fields = snapshot.data ?? widget.fields;
          final scheme = Theme.of(context).colorScheme;

          String? valueFor(String key) {
            final value = fields[key]?.value;
            return (value != null && value.isNotEmpty) ? value : null;
          }

          final sectionWidgets = profileSectionOrder.expand((section) {
            final sectionFields = profileFieldDefs
                .where((def) => def.section == section)
                .map((def) => MapEntry(def, valueFor(def.key)))
                .where((entry) => entry.value != null)
                .toList();

            if (sectionFields.isEmpty) return const <Widget>[];

            return [
              GlassGroupedSection(
                margin: const EdgeInsets.only(bottom: 18),
                shape: const LiquidRoundedSuperellipse(borderRadius: 20),
                quality: GlassQuality.standard,
                header: _buildSectionHeader(
                  context,
                  title: section,
                  icon: _sectionIcon(section),
                ),
                children: sectionFields.map((entry) {
                  final def = entry.key;
                  final value = entry.value!;
                  return GlassListTile(
                    leading: _buildTileLeading(_iconForField(def), scheme),
                    title: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      def.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        color:
                            scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    onTap: () {
                      // Copy value to clipboard on tap
                      Clipboard.setData(ClipboardData(text: value));
                      GlassToast.show(
                        context,
                        message: '${def.label} copied',
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        type: GlassToastType.info,
                        position: GlassToastPosition.bottom,
                        duration: const Duration(milliseconds: 1200),
                      );
                    },
                  );
                }).toList(),
              ),
            ];
          }).toList();

          final hasAny = sectionWidgets.isNotEmpty;

          return Material(
            type: MaterialType.transparency,
            child: CustomScrollView(
              controller: _titleController.scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).padding.top + kToolbarHeight,
                  ),
                ),
                GlassLargeTitle(
                  text: 'Full Info',
                  controller: _titleController,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (!hasAny)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.person_search_outlined,
                                  size: 48,
                                  color: scheme.onSurfaceVariant.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No additional info yet',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Edit your profile to add more details',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: scheme.onSurfaceVariant.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...sectionWidgets,
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
