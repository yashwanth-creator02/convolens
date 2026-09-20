import 'package:flutter/material.dart';

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

IconData callTypeIcon(int type) {
  switch (type) {
    case 1:
      return Icons.call_received;
    case 2:
      return Icons.call_made;
    case 3:
      return Icons.call_missed;
    case 4:
      return Icons.voicemail_outlined;
    case 5:
      return Icons.call_end;
    case 6:
      return Icons.block;
    default:
      return Icons.phone_outlined;
  }
}
