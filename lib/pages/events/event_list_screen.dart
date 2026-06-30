import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/event_model.dart';
import '../../../services/event_service.dart';
import '../../../widgets/filter.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  String _filter = 'Upcoming';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: FilterWidget(
              options: const ['Upcoming', 'Concluded'],
              selectedValue: _filter,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _filter = value;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final now = DateTime.now();
                final eventService = ref.watch(eventServiceProvider);
                final eventsStream = eventService.getEventsForMonth(now.year, now.month);

                return StreamBuilder<List<EventModel>>(
                  stream: eventsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    
                    var events = snapshot.data ?? [];
                    
                    if (_filter == 'Upcoming') {
                      events = events.where((e) => !e.isEnded).toList();
                      events.sort((a, b) => a.date.compareTo(b.date));
                    } else {
                      events = events.where((e) => e.isEnded).toList();
                      events.sort((a, b) => b.date.compareTo(a.date));
                    }

                    if (events.isEmpty) {
                      return Center(child: Text("No $_filter events found."));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final isMultiDay = event.endDate.isAfter(event.date) && 
                                           (event.endDate.day != event.date.day || event.endDate.month != event.date.month);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: event.isEnded 
                                    ? Colors.grey.withValues(alpha: 0.1) 
                                    : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  isMultiDay 
                                      ? "${DateFormat('dd').format(event.date)}-${DateFormat('dd').format(event.endDate)}\n${DateFormat('MMM').format(event.date)}"
                                      : DateFormat('dd\nMMM').format(event.date),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: event.isEnded ? Colors.grey : Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              event.name, 
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: event.isEnded ? Colors.grey : Colors.black,
                              )
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.location),
                                if (event.isEnded)
                                  const Text(
                                    "Concluded", 
                                    style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventDetailScreen(event: event),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
