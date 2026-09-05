/// Shared identifiers for [GlassBarItem]s across the app.
///
/// If the liquid glass package keys morph/continuity animations off
/// bar-item ids when the same id persists across screens, reusing an
/// id (rather than inventing a new string per screen) is what lets an
/// icon morph smoothly into its counterpart instead of just swapping.
class GlassActionIds {
  GlassActionIds._();

  static const String search = 'context_action';
  static const String contactSearch = 'contact_search';
  static const String settings = 'settings';
}
