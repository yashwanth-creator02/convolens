import '../../../core/database/app_database.dart';
import 'group_calls_by_day.dart';

List<Object> buildHistoryItems(List<Call> calls) {
  final grouped = groupCallsByDay(calls);
  final items = <Object>[];

  grouped.forEach((label, callsInGroup) {
    items.add(label);
    items.addAll(callsInGroup);
  });

  return items;
}
