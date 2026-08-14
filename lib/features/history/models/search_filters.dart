class SearchFilters {
  final String contactQuery;
  final String noteQuery;
  final String tagQuery;
  final bool hasAttachment;
  final bool hasReminder;

  const SearchFilters({
    this.contactQuery = '',
    this.noteQuery = '',
    this.tagQuery = '',
    this.hasAttachment = false,
    this.hasReminder = false,
  });

  bool get isEmpty =>
      contactQuery.isEmpty &&
      noteQuery.isEmpty &&
      tagQuery.isEmpty &&
      !hasAttachment &&
      !hasReminder;

  SearchFilters copyWith({
    String? contactQuery,
    String? noteQuery,
    String? tagQuery,
    bool? hasAttachment,
    bool? hasReminder,
  }) {
    return SearchFilters(
      contactQuery: contactQuery ?? this.contactQuery,
      noteQuery: noteQuery ?? this.noteQuery,
      tagQuery: tagQuery ?? this.tagQuery,
      hasAttachment: hasAttachment ?? this.hasAttachment,
      hasReminder: hasReminder ?? this.hasReminder,
    );
  }
}
