import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/event_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../models/organizer_model.dart';
import '../../../providers/organizer_provider.dart';

class EventDetailScreen extends ConsumerWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for real-time updates of this specific event
    final eventAsync = ref.watch(singleEventProvider(event.id));

    final user = ref.watch(currentUserProvider);
    final isVendor = user?.role.name.toLowerCase() == 'vendor';
    final organizerId = user?.organizerId;
    final eventService = ref.watch(eventServiceProvider);
    final organizerService = ref.watch(OrganizerServiceProvider);

    return eventAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(event.name)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(body: Center(child: Text("Error: $err"))),
      data: (updatedEvent) {
        final currentEvent = updatedEvent ?? event;
        final hasJoined = organizerId != null && currentEvent.attendingOrganizerIds.contains(organizerId);
        
        final isMultiDay = currentEvent.endDate.isAfter(currentEvent.date) && 
                           (currentEvent.endDate.day != currentEvent.date.day || currentEvent.endDate.month != currentEvent.date.month);

        return Scaffold(
          appBar: AppBar(title: Text(currentEvent.name)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (currentEvent.isEnded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "CONCLUDED",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      isMultiDay 
                        ? "${DateFormat('MMM dd').format(currentEvent.date)} - ${DateFormat('MMM dd, yyyy').format(currentEvent.endDate)}"
                        : DateFormat('MMMM dd, yyyy').format(currentEvent.date)
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(currentEvent.location),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Description",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(currentEvent.description),
                const SizedBox(height: 30),
                Text(
                  "Attending Vendors",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (currentEvent.attendingOrganizerIds.isEmpty)
                  const Text("No vendors attending yet.")
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
                                backgroundImage: organizer.imageUrl != null ? NetworkImage(organizer.imageUrl!) : null,
                                child: organizer.imageUrl == null ? const Icon(Icons.store) : null,
                              ),
                              title: Text(organizer.organizerName),
                              onTap: () {
                                 Navigator.pushNamed(
                                  context,
                                  '/vendor-profile',
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
                if (isVendor && organizerId != null && !currentEvent.isEnded)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (hasJoined) {
                          await eventService.leaveEvent(currentEvent.id, organizerId);
                        } else {
                          await eventService.joinEvent(currentEvent.id, organizerId);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasJoined
                            ? Colors.red
                            : Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
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
