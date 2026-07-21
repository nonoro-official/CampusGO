import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/event_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../models/organizer_model.dart';
import '../../../providers/organizer_provider.dart';
import '../../../providers/notification_provider.dart';

import 'edit_event_screen.dart';
import 'delete_event_screen.dart';

class EventDetailScreen extends ConsumerWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for real-time updates of this specific event
    final eventAsync = ref.watch(singleEventProvider(event.id));

    final user = ref.watch(currentUserProvider);
    final isOrganizer = user?.role.name.toLowerCase() == 'organizer';
    final organizerId = user?.organizerId;
    final eventService = ref.watch(eventServiceProvider);
    final organizerService = ref.watch(organizerServiceProvider);

    return eventAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(event.name)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(body: Center(child: Text("Error: $err"))),
      data: (updatedEvent) {
        final currentEvent = updatedEvent ?? event;
        final hasJoined = organizerId != null &&
            currentEvent.attendingOrganizerIds.contains(organizerId);

        final isCreator =
            organizerId != null && currentEvent.creatorId == organizerId;

        final isMultiDay = currentEvent.endDate.isAfter(currentEvent.date) &&
            (currentEvent.endDate.day != currentEvent.date.day ||
                currentEvent.endDate.month != currentEvent.date.month);

        final notifPrefs = ref.watch(notificationPreferencesProvider).value;
        final isReminded =
            notifPrefs?.remindedEventIds.contains(currentEvent.id) ?? false;

        return Scaffold(
          appBar: AppBar(
            title: Text(currentEvent.name),
            actions: [
              if (!currentEvent.isEnded)
                IconButton(
                  icon: Icon(
                    isReminded ? Icons.notifications_active : Icons.notifications_none,
                    color: isReminded ? Theme.of(context).primaryColor : null,
                  ),
                  tooltip: isReminded ? "Remove Reminder" : "Notify Me",
                  onPressed: () {
                    ref
                        .read(notificationPreferencesProvider.notifier)
                        .toggleEventReminder(currentEvent);
                    
                    final nextTime = currentEvent.date;
                    final timeStr = DateFormat('hh:mm a').format(nextTime);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isReminded
                            ? "Reminder removed"
                            : "Reminder set for $timeStr! Check settings for 1-day/week options."),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              if (isCreator) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: "Edit Event",
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditEventScreen(event: currentEvent),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: "Delete Event",
                  onPressed: () async {
                    final deletedSuccessfully = await showDialog<bool>(
                      context: context,
                      builder: (_) =>
                          DeleteEventScreen(eventId: currentEvent.id),
                    );

                    if (deletedSuccessfully == true && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Event deleted successfully.")),
                      );
                    }
                  },
                ),
              ]
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentEvent.status == 'pending')
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_empty,
                            color: Colors.amber.shade800),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "This event is currently pending approval from admin, thus it may not be visible to all users yet.",
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (currentEvent.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      currentEvent.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        currentEvent.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (currentEvent.isEnded)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "CONCLUDED",
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(isMultiDay
                          ? "${DateFormat('MMM dd, hh:mm a').format(currentEvent.date)} - ${DateFormat('MMM dd, yyyy, hh:mm a').format(currentEvent.endDate)}"
                          : "${DateFormat('MMMM dd, yyyy').format(currentEvent.date)} (${DateFormat('hh:mm a').format(currentEvent.date)} - ${DateFormat('hh:mm a').format(currentEvent.endDate)})"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                        "${currentEvent.location}${currentEvent.floor != null ? ' - ${currentEvent.floor}' : ''}"),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Description",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(currentEvent.description),
                const SizedBox(height: 30),
                Text(
                  "Attending Organizers",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (currentEvent.attendingOrganizerIds.isEmpty)
                  const Text("No organizers attending yet.")
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentEvent.attendingOrganizerIds.length,
                    itemBuilder: (context, index) {
                      final bId = currentEvent.attendingOrganizerIds[index];
                      return FutureBuilder<OrganizerModel?>(
                        future: organizerService.getOrganizer(bId),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            final organizer = snapshot.data!;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundImage: organizer.imageUrl != null
                                    ? NetworkImage(organizer.imageUrl!)
                                    : null,
                                child: organizer.imageUrl == null
                                    ? const Icon(Icons.store)
                                    : null,
                              ),
                              title: Text(organizer.organizerName),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/organizer-profile',
                                  arguments: organizer,
                                );
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                const SizedBox(height: 40),
                if (isOrganizer && organizerId != null && !currentEvent.isEnded)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (hasJoined) {
                          await eventService.leaveEvent(
                              currentEvent.id, organizerId);
                        } else {
                          await eventService.joinEvent(
                              currentEvent.id, organizerId);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasJoined
                            ? Colors.red
                            : Theme.of(context).primaryColor,
                        foregroundColor: hasJoined
                            ? Colors.white
                            : Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.onPrimary
                                : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        hasJoined ? "Leave Event" : "Join Event",
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
