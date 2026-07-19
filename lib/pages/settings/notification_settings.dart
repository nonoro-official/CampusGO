import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/top_bar.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: TopBar(
        title: 'Notification Settings',
        showBack: true,
        dark: false,
        center: true,
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (prefs) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(context, 'Event Reminders'),
            SwitchListTile(
              title: const Text('When Event Starts'),
              subtitle: const Text('Get notified exactly when the event begins'),
              value: prefs.notifyAtStart,
              onChanged: (val) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .setNotifyAtStart(val),
              activeColor: Theme.of(context).primaryColor,
            ),
            SwitchListTile(
              title: const Text('1 Day Before'),
              subtitle: const Text('A reminder 24 hours before the event'),
              value: prefs.notifyOneDayBefore,
              onChanged: (val) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .setNotifyOneDayBefore(val),
              activeColor: Theme.of(context).primaryColor,
            ),
            SwitchListTile(
              title: const Text('1 Week Before'),
              subtitle: const Text('A heads up 7 days before the event'),
              value: prefs.notifyOneWeekBefore,
              onChanged: (val) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .setNotifyOneWeekBefore(val),
              activeColor: Theme.of(context).primaryColor,
            ),
            const Divider(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Note: You must enable reminders for individual events in their detail pages to receive these notifications.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
