import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/local_notification_service.dart';
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
            FutureBuilder<bool?>(
              future: LocalNotificationService.notificationsPlugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>()
                  ?.areNotificationsEnabled(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == false) {
                  return _buildWarning(
                    context,
                    "Notifications are disabled in system settings. Please enable them to receive reminders.",
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            FutureBuilder<bool?>(
              future: LocalNotificationService.notificationsPlugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>()
                  ?.canScheduleExactNotifications(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == false) {
                  return Column(
                    children: [
                      _buildWarning(
                        context,
                        "Exact alarms are not permitted. Reminders may be delayed by several minutes.",
                      ),
                      TextButton(
                        onPressed: () async {
                          await LocalNotificationService.notificationsPlugin
                              .resolvePlatformSpecificImplementation<
                                  AndroidFlutterLocalNotificationsPlugin>()
                              ?.requestExactAlarmsPermission();
                        },
                        child: const Text("Allow Exact Alarms"),
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
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
            ElevatedButton.icon(
              onPressed: () async {
                await LocalNotificationService.notificationsPlugin.show(
                  id: 999,
                  title: 'Test Notification',
                  body: 'If you see this, notifications are working!',
                  notificationDetails: NotificationDetails(
                    android: AndroidNotificationDetails(
                      'event_reminders',
                      'Event Reminders',
                      importance: Importance.max,
                      priority: Priority.high,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Send Test Notification'),
            ),
            const SizedBox(height: 20),
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

  Widget _buildWarning(BuildContext context, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
