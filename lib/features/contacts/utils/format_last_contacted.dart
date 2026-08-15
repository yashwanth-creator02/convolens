String formatLastContacted(int timestamp) {
  final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final now = DateTime.now();

  final difference = now.difference(dateTime);

  if (difference.isNegative || difference.inMinutes < 1) {
    return 'Just now';
  }

  if (difference.inHours < 1) {
    final minutes = difference.inMinutes;
    return '$minutes minute${minutes == 1 ? '' : 's'} ago';
  }

  if (difference.inDays < 1) {
    final hours = difference.inHours;
    return '$hours hour${hours == 1 ? '' : 's'} ago';
  }

  if (difference.inDays < 7) {
    final days = difference.inDays;
    return '$days day${days == 1 ? '' : 's'} ago';
  }

  if (dateTime.year == now.year) {
    return '${_monthName(dateTime.month)} ${dateTime.day}';
  }

  return '${_monthName(dateTime.month)} ${dateTime.day}, ${dateTime.year}';
}

String _monthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return months[month - 1];
}
