import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../../history/repository/attachment_storage.dart';
import '../models/profile_field_def.dart';
import 'edit_profile_screen.dart';
import 'share_contact_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AppDatabase db;
  final GlassLargeTitleController titleController;

  const ProfileScreen({
    super.key,
    required this.db,
    required this.titleController,
  });

  Future<void> _changePhoto(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.single.path == null) return;

    final savedPath = await AttachmentStorage.saveProfilePhoto(
      result.files.single.path!,
    );
    await db.setProfilePhotoPath(savedPath);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProfileMetaData>(
      stream: db.watchProfileMeta(),
      builder: (context, metaSnapshot) {
        final photoPath = metaSnapshot.data?.photoPath;

        final hasPhoto = photoPath != null && File(photoPath).existsSync();

        return StreamBuilder<Map<String, ProfileFieldEntry>>(
          stream: db.watchProfileFields(),
          builder: (context, fieldsSnapshot) {
            final fields = fieldsSnapshot.data ?? {};

            String? valueFor(String key) {
              final value = fields[key]?.value;
              return (value != null && value.isNotEmpty) ? value : null;
            }

            final displayName =
                valueFor('displayName') ??
                [
                  valueFor('firstName'),
                  valueFor('lastName'),
                ].whereType<String>().join(' ');
            final primaryPhone = valueFor('primaryPhone');

            return Material(
              type: MaterialType.transparency,
              child: CustomScrollView(
                controller: titleController.scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          MediaQuery.of(context).padding.top + kToolbarHeight,
                    ),
                  ),
                  GlassLargeTitle(text: 'Profile', controller: titleController),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => _changePhoto(context),
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundImage: hasPhoto
                                          ? FileImage(File(photoPath))
                                          : null,
                                      child: photoPath == null
                                          ? const Icon(Icons.person, size: 40)
                                          : null,
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        child: const Icon(
                                          Icons.edit,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                displayName.isNotEmpty
                                    ? displayName
                                    : 'Add your name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              if (primaryPhone != null) Text(primaryPhone),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        ...profileSectionOrder.map((section) {
                          final sectionFields = profileFieldDefs
                              .where((def) => def.section == section)
                              .map((def) => MapEntry(def, valueFor(def.key)))
                              .where((entry) => entry.value != null)
                              .toList();

                          if (sectionFields.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const Divider(),
                                ...sectionFields.map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            entry.key.label,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        Expanded(child: Text(entry.value!)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 24),
                        const Text(
                          'Share Contact',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _shareButton(
                              context,
                              'Personal QR',
                              ShareQrType.personal,
                            ),
                            _shareButton(context, 'Work QR', ShareQrType.work),
                            _shareButton(context, 'All QR', ShareQrType.all),
                            _shareButton(
                              context,
                              'Custom QR',
                              ShareQrType.custom,
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _shareButton(BuildContext context, String label, ShareQrType type) {
    return OutlinedButton(
      onPressed: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ShareContactScreen(db: db, type: type),
          ),
        );
      },
      child: Text(label),
    );
  }
}
