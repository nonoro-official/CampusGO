import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;
import '../models/organizer_model.dart';
import '../models/enums.dart';

class OrganizerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Called from register_Organizer.dart
  Future<void> createOrganizer({
    required String ownerId,
    required String organizerName,
    required String contactEmail,
    required String contactNumber,
    required OrganizerPartner organizerPartner,
  }) async {
    final ref = await _db.collection('organizers').add({
      'ownerId': ownerId,
      'organizerName': organizerName,
      'contactEmail': contactEmail,
      'contactNumber': contactNumber,
      'organizerPartner': organizerPartner.name, // Store as string
      'activeStatus': ActiveStatus.closed.name,
      'description': null,
      'OrganizerHours': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Link Organizer back to the organizer's user doc
    await _db.collection('users').doc(ownerId).update({'organizerId': ref.id});
  }

  // Updated to use ActiveStatus enum and correct key 'activeStatus'
  Future<void> updateStatus(
    String organizerId,
    ActiveStatus status, {
    String? eta,
  }) async {
    await _db.collection('organizers').doc(organizerId).update({
      'activeStatus': status.name, // Use .name to store string "open", etc.
      'eta': eta,
    });
  }

  // Edit profile
  Future<void> updateProfile({
    required String organizerId,
    String? description,
  }) async {
    final Map<String, dynamic> data = {};
    if (description != null) data['description'] = description;
    if (data.isEmpty) return;
    await _db.collection('organizers').doc(organizerId).update(data);
  }

  Future<void> updateOrganizerImage(String organizerId, File imageFile) async {
    try {
      // 1. Get the extension (.jpg or .png)
      String extension = p.extension(imageFile.path);

      // 2. Create the reference
      final ref = FirebaseStorage.instance
          .ref()
          .child('organizer_logos')
          .child('$organizerId$extension');

      // 3. Upload the file
      await ref.putFile(imageFile);

      // 4. Get the URL and save to Firestore
      String downloadUrl = await ref.getDownloadURL();
      await _db.collection('organizers').doc(organizerId).update({
        'imageUrl': downloadUrl,
      });
    } on FirebaseException catch (e) {
      debugPrint("Firebase Storage Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("General Error: $e");
      rethrow;
    }
  }

  // Keep your existing updateOrganizerData for generic map updates
  Future<void> updateOrganizerData({
    required String organizerId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection('organizers').doc(organizerId).update(data);
    } catch (e) {
      throw Exception("Failed to update Organizer: $e");
    }
  }

  // Getters

  Future<OrganizerModel?> getOrganizer(String organizerId) async {
    final doc = await _db.collection('organizers').doc(organizerId).get();
    if (!doc.exists) return null;
    return OrganizerModel.fromMap(doc.data()!, doc.id);
  }

  Stream<OrganizerModel?> getOrganizerStream(String organizerId) {
    return _db
        .collection('organizers')
        .doc(organizerId)
        .snapshots()
        .map(
          (doc) =>
              doc.exists ? OrganizerModel.fromMap(doc.data()!, doc.id) : null,
        );
  }

  Future<OrganizerModel?> getMyOrganizer(String ownerId) async {
    final query = await _db
        .collection('organizers')
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return OrganizerModel.fromMap(query.docs.first.data(), query.docs.first.id);
  }

  Stream<List<OrganizerModel>> getAllOrganizers() {
    return _db
        .collection('organizers')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OrganizerModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
