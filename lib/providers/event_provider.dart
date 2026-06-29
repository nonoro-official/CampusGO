import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/models/event_model.dart';
import '../lib/services/event_service.dart';

// 1. Provider for the Service itself
final eventServiceProvider = Provider((ref) => EventService());

// 2. StreamProvider for the list of events (used in EventListScreen)
final monthlyEventsProvider = StreamProvider.family<List<EventModel>, DateTime>((ref, date) {
  final service = ref.watch(eventServiceProvider);
  return service.getEventsForMonth(date.year, date.month);
});

// 3. StreamProvider for a SINGLE event (used in EventDetailScreen)
// This listens to a specific document ID for real-time updates
final singleEventProvider = StreamProvider.family<EventModel?, String>((ref, eventId) {
  return FirebaseFirestore.instance
      .collection('events')
      .doc(eventId)
      .snapshots()
      .map((doc) => doc.exists
      ? EventModel.fromMap(doc.data()!, doc.id)
      : null);
});