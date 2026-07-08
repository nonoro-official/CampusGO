import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../widgets/welcome_card.dart';
import '../../widgets/recommended_row.dart';
import '../../providers/auth_provider.dart';
import '../../providers/organizer_provider.dart';
import '../../services/event_service.dart';
import '../../models/event_model.dart';
import '../../models/organizer_model.dart';
import '../../pages/events/event_list_screen.dart';
import '../../pages/events/event_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  final bool isOrganizer;
  const HomeScreen({super.key, this.isOrganizer = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);
    final roleName = user?.role.name.toLowerCase() ?? 'guest';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: isOrganizer ? 80 : 20),
          const WelcomeCard(),
          const SizedBox(height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Upcoming Events", style: textTheme.titleMedium),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EventListScreen()),
                  );
                },
                child: const Text("See All"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const EventCarousel(),
          const SizedBox(height: 30),

          Text("Announcements", style: textTheme.titleMedium),
          const SizedBox(height: 15),
          const AnnouncementBar(),
          const SizedBox(height: 30),

          if (roleName == 'customer') ...[
            Text("Recommended for You", style: textTheme.titleMedium),
            const SizedBox(height: 15),
            const RecommendedRow(),
            const SizedBox(height: 30),
          ],

          Text("Organizations", style: textTheme.titleMedium),
          const SizedBox(height: 15),
          const OrganizationListView(shrinkWrap: true),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class EventCarousel extends ConsumerWidget {
  const EventCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final eventService = ref.watch(eventServiceProvider);

    return StreamBuilder<List<EventModel>>(
      stream: eventService.getEventsForMonth(now.year, now.month),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final events = snapshot.data?.where((e) => !e.isEnded).toList() ?? [];
        
        if (events.isEmpty) {
           return Container(
             width: double.infinity,
             height: 100,
             decoration: BoxDecoration(
               color: Colors.grey[50],
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: Colors.grey[200]!),
             ),
             child: const Center(
               child: Text(
                 "No upcoming events this month.",
                 style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
               ),
             ),
           );
        }

        return SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isMultiDay = event.endDate.isAfter(event.date) && 
                                 (event.endDate.day != event.date.day || event.endDate.month != event.date.month);

              return GestureDetector(
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailScreen(event: event),
                    ),
                  );
                },
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: event.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(event.imageUrl!),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.4),
                              BlendMode.darken,
                            ),
                          )
                        : null,
                    color: Theme.of(context).primaryColor,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        isMultiDay 
                            ? "${DateFormat('MMM dd').format(event.date)} - ${DateFormat('MMM dd').format(event.endDate)} @ ${event.location}"
                            : "${DateFormat('MMM dd').format(event.date)} @ ${event.location}",
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${event.attendingOrganizerIds.length} Organizers Attending",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class AnnouncementBar extends StatelessWidget {
  const AnnouncementBar({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    final announcements = [
      {"title": "Chunky Bites 20% OFF!", "subtitle": "Limited time promo 🍔"},
      {"title": "Lemon Frenzy Buy 1 Take 1", "subtitle": "Today only 🥤"},
      {
        "title": "Free Delivery on Campus Orders",
        "subtitle": "Min. ₱100 purchase",
      },
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final item = announcements[index];

          return Container(
            width: 220,
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["title"]!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(item["subtitle"]!, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OrganizationListView extends ConsumerWidget {
  final bool shrinkWrap;
  const OrganizationListView({super.key, this.shrinkWrap = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOrganizersAsync = ref.watch(allOrganizersProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return allOrganizersAsync.when(
      data: (organizers) {
        if (organizers.isEmpty) {
          return const Center(child: Text("No organizers found"));
        }

        return ListView.builder(
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          padding: shrinkWrap ? EdgeInsets.zero : const EdgeInsets.fromLTRB(12, 12, 12, 100),
          itemCount: organizers.length,
          itemBuilder: (context, index) {
            final organizer = organizers[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                  backgroundImage: (organizer.imageUrl != null && organizer.imageUrl!.isNotEmpty)
                    ? NetworkImage(organizer.imageUrl!) 
                    : null,
                  child: (organizer.imageUrl == null || organizer.imageUrl!.isEmpty)
                    ? Icon(Icons.business, color: primaryColor) 
                    : null,
                ),
                title: Text(
                  organizer.organizerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  organizer.description ?? "No description available",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/organizer-profile',
                    arguments: organizer,
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
    );
  }
}
