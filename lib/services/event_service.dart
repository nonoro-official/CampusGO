import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> joinEvent(String eventId, String OrganizerId) async {
    await _db.collection('events').doc(eventId).update({
      'attendingOrganizerIds': FieldValue.arrayUnion([OrganizerId])
    });
  }

  Future<void> leaveEvent(String eventId, String OrganizerId) async {
    await _db.collection('events').doc(eventId).update({
      'attendingOrganizerIds': FieldValue.arrayRemove([OrganizerId])
    });
  }

  Future<String> createEvent(EventModel event) async {
    final docRef = await _db.collection('events').add(event.toMap());
    return docRef.id;
  }

  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _db.collection('events').doc(id).update(data);
  }

  Future<void> uploadEventImage(String eventId, File imageFile) async {
    String extension = p.extension(imageFile.path);
    final ref = FirebaseStorage.instance
        .ref()
        .child('event_images')
        .child('$eventId$extension');

    await ref.putFile(imageFile);
    String downloadUrl = await ref.getDownloadURL();
    await _db.collection('events').doc(eventId).update({
      'imageUrl': downloadUrl,
    });
  }

  Future<void> deleteEvent(String id) async {
    await _db.collection('events').doc(id).delete();
  }

  // Password confirmation check for sensitive actions like deleting an event
  Future<bool> verifyPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return true; // Password is correct
    } catch (_) {
      return false; // Password is incorrect or some other error occurred
    }
  }
}

final eventServiceProvider = Provider((ref) => EventService());
