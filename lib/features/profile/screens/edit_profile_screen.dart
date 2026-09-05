import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../models/profile_field_def.dart';

class EditProfileScreen extends StatefulWidget {
  final AppDatabase db;

  const EditProfileScreen({super.key, required this.db});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _titleController = GlassLargeTitleController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Edit Details'),
        largeTitleController: _titleController,
      ),
      body: StreamBuilder<Map<String, ProfileFieldEntry>>(
        stream: widget.db.watchProfileFields(),
        builder: (context, snapshot) {
          final fields = snapshot.data ?? {};

          return Material(
            type: MaterialType.transparency,
            child: CustomScrollView(
              controller: _titleController.scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + kToolbarHeight,
                  ),
                ),
                GlassLargeTitle(
                  text: 'Edit Details',
                  controller: _titleController,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      profileSectionOrder.map((section) {
                        final sectionDefs = profileFieldDefs
                            .where((def) => def.section == section)
                            .toList();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
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
                              ...sectionDefs.map(
                                (def) => _FieldEditor(
                                  def: def,
                                  entry: fields[def.key],
                                  db: widget.db,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FieldEditor extends StatefulWidget {
  final ProfileFieldDef def;
  final ProfileFieldEntry? entry;
  final AppDatabase db;

  const _FieldEditor({
    required this.def,
    required this.entry,
    required this.db,
  });

  @override
  State<_FieldEditor> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<_FieldEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.entry?.value ?? '');
  }

  @override
  void didUpdateWidget(covariant _FieldEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incomingValue = widget.entry?.value ?? '';
    if (_controller.text != incomingValue && !_controller.selection.isValid) {
      _controller.text = incomingValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextInputType _keyboardTypeFor(FieldInputType type) {
    switch (type) {
      case FieldInputType.phone:
        return TextInputType.phone;
      case FieldInputType.email:
        return TextInputType.emailAddress;
      case FieldInputType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shared = widget.entry?.shared ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: _keyboardTypeFor(widget.def.type),
              maxLines: widget.def.type == FieldInputType.multiline ? 3 : 1,
              decoration: InputDecoration(labelText: widget.def.label),
              onChanged: (value) =>
                  widget.db.setProfileFieldValue(widget.def.key, value),
            ),
          ),
          Column(
            children: [
              const Text(
                'Share',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Switch(
                value: shared,
                onChanged: (value) =>
                    widget.db.setProfileFieldShared(widget.def.key, value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
