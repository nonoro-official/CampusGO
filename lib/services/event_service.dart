import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<EventModel>> getEventsForMonth(int year, int month) {
    // Get the first and last day of the month
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    // We want events that either start or end within this month, 
    // or are ongoing during this month.
    // For simplicity, let's fetch events that start before the end of the month
    // and end after the start of the month.
    return _db
        .collection('events')
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .snapshots()
        .map((snapshot) {
          final allEvents = snapshot.docs
              .map((doc) => EventModel.fromMap(doc.data(), doc.id))
              .toList();
          
          // Filter in memory for the second condition since Firestore allows only one range filter on different fields
          return allEvents.where((event) {
            return event.endDate.isAfter(startOfMonth) || event.endDate.isAtSameMomentAs(startOfMonth);
          }).toList();
        });
  }

  Future<void> joinEvent(String eventId, String businessId) async {
    await _db.collection('events').doc(eventId).update({
      'attendingBusinessIds': FieldValue.arrayUnion([businessId])
    });
  }

  Future<void> leaveEvent(String eventId, String businessId) async {
    await _db.collection('events').doc(eventId).update({
      'attendingBusinessIds': FieldValue.arrayRemove([businessId])
    });
  }

  Future<void> createEvent(EventModel event) async {
    await _db.collection('events').add(event.toMap());
  }
}

final eventServiceProvider = Provider((ref) => EventService());
