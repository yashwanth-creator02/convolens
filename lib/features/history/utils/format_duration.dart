String formatDuration(int seconds) {
  if (seconds <= 0) return '0s';

  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;

  if (h > 0) {
    if (m > 0) {
      return '${h}h ${m}m';
    }
    return '${h}h';
  } else if (m > 0) {
    if (s > 0) {
      return '${m}m ${s}s';
    }
    return '${m}m';
  } else {
    return '${s}s';
  }
}
