String callTypeLabel(int type) {
  switch (type) {
    case 1:
      return 'Incoming';
    case 2:
      return 'Outgoing';
    case 3:
      return 'Missed';
    case 4:
      return 'Voicemail';
    case 5:
      return 'Rejected';
    case 6:
      return 'Blocked';
    default:
      return 'Unknown';
  }
}
