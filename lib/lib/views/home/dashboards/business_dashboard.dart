import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:unimart/providers/auth_provider.dart';
import 'package:unimart/providers/business_provider.dart';
import '../../../models/event_model.dart';
import '../../../services/event_service.dart';
import '../events/event_list_screen.dart';
import '../widgets/vendor_shop_card.dart';
import '../widgets/analytics_grid.dart';
import '../widgets/vendor_actions_row.dart';

class BusinessDashboard extends ConsumerWidget {
  const BusinessDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);
    final businessAsync = ref.watch(myBusinessProvider);

    return businessAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text("Error: $err"))),
      data: (business) {
        if (business == null) return const Scaffold(body: Center(child: Text("No business found")));

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80), // Space for toggle buttons
              const VendorShopCard(),
              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Events", style: textTheme.titleMedium),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EventListScreen()),
                      );
                    },
                    child: const Text("Join Events"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const BusinessEventSection(),

              const SizedBox(height: 25),

              Text("Today's Analytics", style: textTheme.titleMedium),
              const SizedBox(height: 15),
              AnalyticsGrid(businessId: user!.businessId!),

              const SizedBox(height: 10),

              Text("Quick Actions", style: textTheme.titleMedium),
              const SizedBox(height: 15),
              const VendorActionsRow(),

              const SizedBox(height: 120), // Bottom padding for navbar
            ],
          ),
        );
      },
    );
  }
}

class BusinessEventSection extends ConsumerWidget {
  const BusinessEventSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final eventService = ref.watch(eventServiceProvider);
    final business = ref.watch(myBusinessProvider).value;

    if (business == null) return const SizedBox.shrink();

    return StreamBuilder<List<EventModel>>(
      stream: eventService.getEventsForMonth(now.year, now.month),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allEvents = snapshot.data ?? [];
        final upcomingEvents = allEvents.where((e) => !e.isEnded).toList();

        if (upcomingEvents.isEmpty) {
          return _buildEmptyState(context, "No upcoming events scheduled.");
        }

        final attendingEvents = upcomingEvents
            .where((e) => e.attendingBusinessIds.contains(business.id))
            .toList();

        if (attendingEvents.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text("You haven't joined any events yet."),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EventListScreen()),
                    );
                  },
                  child: const Text("Browse Events"),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: attendingEvents.length,
            itemBuilder: (context, index) {
              final event = attendingEvents[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd').format(event.date),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
