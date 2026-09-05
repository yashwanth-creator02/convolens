import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationTroubleshootingScreen extends StatelessWidget {
  const NotificationTroubleshootingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(title: const Text('Notification Troubleshooting')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16 + MediaQuery.of(context).padding.top,
          16,
          16,
        ),
        children: [
          const Text(
            'On some phones (especially Infinix, Tecno, Itel, Xiaomi, and Oppo devices), '
            'Android alone is not enough to guarantee reminders fire on time. These brands '
            'run their own battery managers that can silently stop scheduled notifications, '
            'even with permissions granted here in the app.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _step(
            '1. Disable battery optimization',
            'Already available above as "Ignore Battery Optimization" — grant it if you '
                'haven\'t.',
          ),
          _step(
            '2. Enable Autostart for Convolens',
            'Open your phone\'s own Settings app (not this app) → Apps → Convolens → look for '
                '"Autostart" or "Auto-launch," and turn it on. On some phones this instead lives '
                'in a separate "Phone Manager" or "Security" app rather than Settings itself.',
          ),
          _step(
            '3. Lock the app in recent apps',
            'Open your recent apps switcher, find Convolens, and look for a lock icon (often '
                'from a long-press or a small padlock in the corner) — this tells the system not '
                'to kill it when memory is low.',
          ),
          _step(
            '4. Check notification settings directly',
            'Open your phone\'s Settings → Apps → Convolens → Notifications, and make sure '
                'notifications are fully enabled there too, separate from what this app can '
                'control.',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => openAppSettings(),
            icon: const Icon(Icons.settings),
            label: const Text('Open App Settings'),
          ),
        ],
      ),
    );
  }

  Widget _step(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
