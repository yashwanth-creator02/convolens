class RelationshipVitals {
  final int relationshipDays;
  final double averageGapDays;
  final int longestGapDays;

  const RelationshipVitals({
    required this.relationshipDays,
    required this.averageGapDays,
    required this.longestGapDays,
  });
}

RelationshipVitals computeVitals(List<int> timestamps) {
  if (timestamps.isEmpty) {
    return const RelationshipVitals(
      relationshipDays: 0,
      averageGapDays: 0,
      longestGapDays: 0,
    );
  }

  final now = DateTime.now().millisecondsSinceEpoch;
  final relationshipDays =
      ((now - timestamps.first) / (1000 * 60 * 60 * 24)).round();

  if (timestamps.length < 2) {
    return RelationshipVitals(
      relationshipDays: relationshipDays,
      averageGapDays: 0,
      longestGapDays: 0,
    );
  }

  final gaps = <int>[];
  for (int i = 1; i < timestamps.length; i++) {
    final gapDays =
        (timestamps[i] - timestamps[i - 1]) ~/ (1000 * 60 * 60 * 24);
    gaps.add(gapDays);
  }

  final averageGap = gaps.reduce((a, b) => a + b) / gaps.length;
  final longestGap = gaps.reduce((a, b) => a > b ? a : b);

  return RelationshipVitals(
    relationshipDays: relationshipDays,
    averageGapDays: averageGap,
    longestGapDays: longestGap,
  );
}
