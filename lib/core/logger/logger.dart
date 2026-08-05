import 'package:flutter/foundation.dart';

import 'log_level.dart';

class Logger {
  static bool devModeEnabled = false;

  static void debug(String message, {String? tag}) =>
      _log(LogLevel.debug, message, tag: tag);

  static void info(String message, {String? tag}) =>
      _log(LogLevel.info, message, tag: tag);

  static void warning(String message, {String? tag}) =>
      _log(LogLevel.warning, message, tag: tag);

  static void error(String message, {String? tag}) =>
      _log(LogLevel.error, message, tag: tag);

  static void _log(LogLevel level, String message, {String? tag}) {
    if (level == LogLevel.debug && !devModeEnabled) return;

    final prefix = switch (level) {
      LogLevel.debug => '[DEBUG]',
      LogLevel.info => '[INFO]',
      LogLevel.warning => '[WARNING]',
      LogLevel.error => '[ERROR]',
    };

    final tagPart = tag != null ? '[$tag] ' : '';

    debugPrint('$prefix $tagPart$message');
  }
}
