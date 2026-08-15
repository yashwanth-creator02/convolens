import 'package:flutter/material.dart';

class HistoryPermissionView extends StatelessWidget {
  final bool permanentlyDenied;
  final VoidCallback onGrantPermission;
  final VoidCallback onOpenSettings;

  const HistoryPermissionView({
    super.key,
    required this.permanentlyDenied,
    required this.onGrantPermission,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_disabled, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Convolens needs call log permission to show your history.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: permanentlyDenied ? onOpenSettings : onGrantPermission,
              child: Text(
                permanentlyDenied ? 'Open App Settings' : 'Grant Permission',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
