String formatCallTime(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);

  final hour24 = date.hour;
  final minute = date.minute.toString().padLeft(2, '0');

  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;

  return '$hour12:$minute $period';
}
