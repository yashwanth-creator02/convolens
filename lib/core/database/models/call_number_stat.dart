class CallNumberStat {
  final String number;
  final int count;
  final int lastTimestamp;
  final String? name;

  const CallNumberStat({
    required this.number,
    required this.count,
    required this.lastTimestamp,
    this.name,
  });
}
