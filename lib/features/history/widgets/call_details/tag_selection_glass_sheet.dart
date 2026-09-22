import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/database/app_database.dart';

/// A bottom sheet with liquid glass aesthetics and scrollable glass chips
/// for selecting, toggling, and creating tags for a call or contact.
class TagSelectionGlassSheet extends StatefulWidget {
  final AppDatabase db;
  final int? callId;
  final String? contactNormalizedNumber;

  const TagSelectionGlassSheet({
    super.key,
    required this.db,
    this.callId,
    this.contactNormalizedNumber,
  }) : assert(callId != null || contactNormalizedNumber != null,
            'Either callId or contactNormalizedNumber must be provided');

  /// Displays the tag selection sheet for a call in a [GlassSheet].
  static Future<void> show({
    required BuildContext context,
    required AppDatabase db,
    required int callId,
  }) {
    return GlassSheet.show(
      context: context,
      quality: GlassQuality.standard,
      showDragIndicator: true,
      isScrollable: false,
      enableDrag: false,
      interactionScale: 1.0,
      enableSaturationGlow: false,
      enableInteractionGlow: false,
      suppressInteractionOnChildren: true,
      topBorderRadius: 24,
      bottomBorderRadius: 0,
      margin: EdgeInsets.zero,
      builder: (context) => TagSelectionGlassSheet(
        db: db,
        callId: callId,
      ),
    );
  }

  /// Displays the tag selection sheet for a contact in a [GlassSheet].
  static Future<void> showForContact({
    required BuildContext context,
    required AppDatabase db,
    required String normalizedNumber,
  }) {
    return GlassSheet.show(
      context: context,
      quality: GlassQuality.standard,
      showDragIndicator: true,
      isScrollable: false,
      enableDrag: false,
      interactionScale: 1.0,
      enableSaturationGlow: false,
      enableInteractionGlow: false,
      suppressInteractionOnChildren: true,
      topBorderRadius: 24,
      bottomBorderRadius: 0,
      margin: EdgeInsets.zero,
      builder: (context) => TagSelectionGlassSheet(
        db: db,
        contactNormalizedNumber: normalizedNumber,
      ),
    );
  }

  @override
  State<TagSelectionGlassSheet> createState() => _TagSelectionGlassSheetState();
}

class _TagSelectionGlassSheetState extends State<TagSelectionGlassSheet> {
  static const List<String> _suggestedTags = [
    'Work',
    'Personal',
    'Important',
    'Follow-up',
    'Urgent',
    'Meeting',
    'Family',
    'Client',
  ];

  late final TextEditingController _searchController;
  String _query = '';

  bool get _isContact => widget.contactNormalizedNumber != null;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      final text = _searchController.text.trim();
      if (_query != text) {
        setState(() => _query = text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleTag(Tag tag, bool isCurrentlyAssigned) async {
    HapticFeedback.selectionClick();
    if (_isContact) {
      if (isCurrentlyAssigned) {
        await widget.db.removeTagFromContact(widget.contactNormalizedNumber!, tag.id);
      } else {
        await widget.db.addTagToContact(widget.contactNormalizedNumber!, tag.name);
      }
    } else {
      if (isCurrentlyAssigned) {
        await widget.db.removeTagFromCall(widget.callId!, tag.id);
      } else {
        await widget.db.addTagToCall(widget.callId!, tag.name);
      }
    }
  }

  Future<void> _createTag(String tagName) async {
    final name = tagName.trim();
    if (name.isEmpty) return;
    HapticFeedback.mediumImpact();
    if (_isContact) {
      await widget.db.addTagToContact(widget.contactNormalizedNumber!, name);
    } else {
      await widget.db.addTagToCall(widget.callId!, name);
    }
    _searchController.clear();
  }

  Future<void> _clearAllTags() async {
    HapticFeedback.mediumImpact();
    if (_isContact) {
      await widget.db.clearAllTagsForContact(widget.contactNormalizedNumber!);
    } else {
      await widget.db.clearAllTagsForCall(widget.callId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.68,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pinned Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 12, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_offer_rounded,
                        size: 17,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isContact ? 'Contact Tags' : 'Call Tags',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Pinned Cupertino Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'Search or type new tag…',
                  style: TextStyle(color: scheme.onSurface, fontSize: 14),
                  placeholderStyle: TextStyle(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  prefixInsets: const EdgeInsetsDirectional.fromSTEB(10, 0, 0, 0),
                  suffixInsets: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  borderRadius: BorderRadius.circular(12),
                  backgroundColor:
                      scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  onSubmitted: (value) => _createTag(value),
                ),
              ),

              const SizedBox(height: 6),

              // Scrollable Glass Chips Area
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: StreamBuilder<List<Tag>>(
                    stream: widget.db.watchAllTags(),
                    builder: (context, allTagsSnapshot) {
                      final allTags = allTagsSnapshot.data ?? const [];

                      return StreamBuilder<List<Tag>>(
                        stream: _isContact
                            ? widget.db.watchTagsForContact(
                                widget.contactNormalizedNumber!)
                            : widget.db.watchTagsForCall(widget.callId!),
                        builder: (context, assignedTagsSnapshot) {
                          final assignedTags =
                              assignedTagsSnapshot.data ?? const [];
                          final assignedIds =
                              assignedTags.map((t) => t.id).toSet();

                          // Filter tags by search query
                          final filteredAll = _query.isEmpty
                              ? allTags
                              : allTags
                                  .where((t) => t.name
                                      .toLowerCase()
                                      .contains(_query.toLowerCase()))
                                  .toList();

                          final assignedFiltered = filteredAll
                              .where((t) => assignedIds.contains(t.id))
                              .toList();
                          final availableFiltered = filteredAll
                              .where((t) => !assignedIds.contains(t.id))
                              .toList();

                          final exactMatchExists = allTags.any(
                            (t) => t.name.toLowerCase() == _query.toLowerCase(),
                          );

                          // Suggested tags not yet in allTags
                          final existingNamesLower =
                              allTags.map((t) => t.name.toLowerCase()).toSet();
                          final remainingSuggestions = _suggestedTags
                              .where((s) =>
                                  !existingNamesLower.contains(s.toLowerCase()))
                              .where((s) =>
                                  _query.isEmpty ||
                                  s
                                      .toLowerCase()
                                      .contains(_query.toLowerCase()))
                              .toList();

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Prompt to add new tag if query has no exact match
                              if (_query.isNotEmpty && !exactMatchExists) ...[
                                _buildSectionHeader(
                                  context,
                                  'CREATE NEW TAG',
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    GlassChip(
                                      label: 'Create "$_query"',
                                      icon: Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                        color: scheme.primary,
                                      ),
                                      selected: true,
                                      selectedColor: scheme.primary
                                          .withValues(alpha: 0.22),
                                      labelStyle: TextStyle(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                      quality: GlassQuality.standard,
                                      useOwnLayer: false,
                                      onTap: () => _createTag(_query),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Assigned Tags Section
                              if (assignedFiltered.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildSectionHeader(
                                      context,
                                      'ASSIGNED (${assignedFiltered.length})',
                                    ),
                                    GestureDetector(
                                      onTap: _clearAllTags,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          'Clear All',
                                          style: TextStyle(
                                            color: scheme.error,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: assignedFiltered.map((tag) {
                                    return GlassChip(
                                      label: tag.name,
                                      selected: true,
                                      selectedColor: scheme.primary
                                          .withValues(alpha: 0.25),
                                      icon: Icon(
                                        Icons.check_rounded,
                                        size: 15,
                                        color: scheme.primary,
                                      ),
                                      labelStyle: TextStyle(
                                        color: scheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      quality: GlassQuality.standard,
                                      useOwnLayer: false,
                                      onTap: () => _toggleTag(tag, true),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Available Tags Section
                              if (availableFiltered.isNotEmpty) ...[
                                _buildSectionHeader(
                                  context,
                                  'ALL TAGS (${availableFiltered.length})',
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: availableFiltered.map((tag) {
                                    return GlassChip(
                                      label: tag.name,
                                      selected: false,
                                      icon: Icon(
                                        Icons.tag_rounded,
                                        size: 14,
                                        color: scheme.onSurfaceVariant
                                            .withValues(alpha: 0.8),
                                      ),
                                      labelStyle: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                      quality: GlassQuality.standard,
                                      useOwnLayer: false,
                                      onTap: () => _toggleTag(tag, false),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Suggestions Section
                              if (remainingSuggestions.isNotEmpty) ...[
                                _buildSectionHeader(
                                  context,
                                  'SUGGESTED',
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      remainingSuggestions.map((suggestion) {
                                    return GlassChip(
                                      label: suggestion,
                                      selected: false,
                                      icon: Icon(
                                        Icons.add_rounded,
                                        size: 14,
                                        color: scheme.primary
                                            .withValues(alpha: 0.8),
                                      ),
                                      labelStyle: TextStyle(
                                        color: scheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                      quality: GlassQuality.standard,
                                      useOwnLayer: false,
                                      onTap: () => _createTag(suggestion),
                                    );
                                  }).toList(),
                                ),
                              ],

                              // Search Empty State
                              if (filteredAll.isEmpty &&
                                  remainingSuggestions.isEmpty &&
                                  _query.isNotEmpty) ...[
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      'No tags matching "$_query"',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }
}
