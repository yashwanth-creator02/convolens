import '../../../core/database/app_database.dart';

String dayLabelFor(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final callDay = DateTime(date.year, date.month, date.day);

  final difference = today.difference(callDay).inDays;

  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';

  return '${callDay.day}/${callDay.month}/${callDay.year}';
}

Map<String, List<Call>> groupCallsByDay(List<Call> calls) {
  final Map<String, List<Call>> grouped = {};
  for (final call in calls) {
    final date = DateTime.fromMillisecondsSinceEpoch(call.timestamp);
    final label = dayLabelFor(date);

    grouped.putIfAbsent(label, () => []);
    grouped[label]!.add(call);
  }
  return grouped;
}
