import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Persistent preferences service for the dialer numpad (one-handed mode, alignment, etc.)
class NumpadPreferences {
  static bool _oneHandedMode = false;
  static bool _alignRight = true;
  static bool _initialized = false;

  static bool get oneHandedMode => _oneHandedMode;
  static bool get alignRight => _alignRight;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/numpad_preferences.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        _oneHandedMode = data['oneHandedMode'] as bool? ?? false;
        _alignRight = data['alignRight'] as bool? ?? true;
      }
    } catch (_) {}
    _initialized = true;
  }

  static Future<void> setOneHandedMode(bool enabled) async {
    _oneHandedMode = enabled;
    await _save();
  }

  static Future<void> setAlignRight(bool alignRight) async {
    _alignRight = alignRight;
    await _save();
  }

  static Future<void> _save() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/numpad_preferences.json');
      await file.writeAsString(jsonEncode({
        'oneHandedMode': _oneHandedMode,
        'alignRight': _alignRight,
      }));
    } catch (_) {}
  }
}
