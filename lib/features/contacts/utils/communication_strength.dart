enum StrengthLevel { strong, steady, fading, new_, dormant }

class CommunicationStrength {
  final StrengthLevel level;
  final String label;
  final List<String> reasons;

  const CommunicationStrength(this.level, this.label, this.reasons);
}

CommunicationStrength computeStrength({
  required int callCount,
  required int? lastCallAt,
  required int firstCallAt,
  required int totalDurationSeconds,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final reasons = <String>[];

  if (lastCallAt == null) {
    return const CommunicationStrength(
      StrengthLevel.dormant,
      'No Contact Yet',
      ['You have not called this person.'],
    );
  }

  final daysSinceLastCall = (now - lastCallAt) ~/ (1000 * 60 * 60 * 24);
  final relationshipDays = ((now - firstCallAt) ~/ (1000 * 60 * 60 * 24)).clamp(
    1,
    999999,
  );
  final callsPerMonth = callCount / (relationshipDays / 30).clamp(0.1, 999999);
  final avgDuration = totalDurationSeconds / callCount;

  if (daysSinceLastCall > 90) {
    reasons.add('No calls in over ${(daysSinceLastCall / 30).round()} months');
    return CommunicationStrength(StrengthLevel.dormant, 'Dormant', reasons);
  }

  if (relationshipDays < 30) {
    reasons.add('You started talking recently');
    return CommunicationStrength(StrengthLevel.new_, 'New', reasons);
  }

  if (daysSinceLastCall > 30) {
    reasons.add('Last call was ${daysSinceLastCall} days ago');
    reasons.add('Used to call ${callsPerMonth.toStringAsFixed(1)} times/month');
    return CommunicationStrength(StrengthLevel.fading, 'Fading', reasons);
  }

  if (callsPerMonth >= 4 && avgDuration >= 60) {
    reasons.add('${callsPerMonth.toStringAsFixed(1)} calls/month on average');
    reasons.add(
      'Avg call length: ${(avgDuration / 60).toStringAsFixed(1)} min',
    );
    return CommunicationStrength(StrengthLevel.strong, 'Strong', reasons);
  }

  reasons.add('${callsPerMonth.toStringAsFixed(1)} calls/month');
  reasons.add('Last call ${daysSinceLastCall} days ago');
  return CommunicationStrength(StrengthLevel.steady, 'Steady', reasons);
}
