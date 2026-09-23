class SearchFilters {
  final String query;
  final String contactQuery;
  final String noteQuery;
  final String tagQuery;
  final Set<String> selectedTags;
  final bool hasAttachment;
  final bool hasReminder;
  final bool hasNotes;
  final int? callType;

  const SearchFilters({
    this.query = '',
    this.contactQuery = '',
    this.noteQuery = '',
    this.tagQuery = '',
    this.selectedTags = const {},
    this.hasAttachment = false,
    this.hasReminder = false,
    this.hasNotes = false,
    this.callType,
  });

  bool get isEmpty =>
      query.isEmpty &&
      contactQuery.isEmpty &&
      noteQuery.isEmpty &&
      tagQuery.isEmpty &&
      selectedTags.isEmpty &&
      !hasAttachment &&
      !hasReminder &&
      !hasNotes &&
      callType == null;

  int get activeFilterCount {
    var count = 0;
    if (hasAttachment) count++;
    if (hasReminder) count++;
    if (hasNotes) count++;
    if (tagQuery.isNotEmpty) count++;
    if (selectedTags.isNotEmpty) count += selectedTags.length;
    if (callType != null) count++;
    return count;
  }

  SearchFilters copyWith({
    String? query,
    String? contactQuery,
    String? noteQuery,
    String? tagQuery,
    Set<String>? selectedTags,
    bool? hasAttachment,
    bool? hasReminder,
    bool? hasNotes,
    int? Function()? callType,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      contactQuery: contactQuery ?? this.contactQuery,
      noteQuery: noteQuery ?? this.noteQuery,
      tagQuery: tagQuery ?? this.tagQuery,
      selectedTags: selectedTags ?? this.selectedTags,
      hasAttachment: hasAttachment ?? this.hasAttachment,
      hasReminder: hasReminder ?? this.hasReminder,
      hasNotes: hasNotes ?? this.hasNotes,
      callType: callType != null ? callType() : this.callType,
    );
  }

  SearchFilters reset() => const SearchFilters();
}
