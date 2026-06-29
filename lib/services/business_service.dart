import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;
import '../models/business_model.dart';
import '../models/enums.dart';
import '../models/business_hours.dart';

class BusinessService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Called from register_business.dart
  Future<void> createBusiness({
    required String ownerId,
    required String businessName,
    required String contactEmail,
    required String contactNumber,
    required BusinessPartner businessPartner,
  }) async {
    final ref = await _db.collection('businesses').add({
      'ownerId': ownerId,
      'businessName': businessName,
      'contactEmail': contactEmail,
      'contactNumber': contactNumber,
      'businessPartner': businessPartner.name, // Store as string
      'activeStatus': ActiveStatus.closed.name,
      'category': 'Others', // Default category
      'description': null,
      'businessHours': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Link business back to the vendor's user doc
    await _db.collection('users').doc(ownerId).update({'businessId': ref.id});
  }

  // Updated to use ActiveStatus enum and correct key 'activeStatus'
  Future<void> updateStatus(
    String businessId,
    ActiveStatus status, {
    String? eta,
  }) async {
    await _db.collection('businesses').doc(businessId).update({
      'activeStatus': status.name, // Use .name to store string "open", etc.
      'eta': eta,
    });
  }

  // Edit profile
  Future<void> updateProfile({
    required String businessId,
    String? description,
    Map<String, BusinessHours>? hours,
  }) async {
    final Map<String, dynamic> data = {};
    if (description != null) data['description'] = description;
    if (hours != null) {
      data['businessHours'] = hours.map((k, v) => MapEntry(k, v.toMap()));
    }
    if (data.isEmpty) return;
    await _db.collection('businesses').doc(businessId).update(data);
  }

  Future<void> updateBusinessImage(String businessId, File imageFile) async {
    try {
      // 1. Get the extension (.jpg or .png)
      String extension = p.extension(imageFile.path);

      // 2. Create the reference
      final ref = FirebaseStorage.instance
          .ref()
          .child('business_logos')
          .child('$businessId$extension');

      // 3. Upload the file
      await ref.putFile(imageFile);

      // 4. Get the URL and save to Firestore
      String downloadUrl = await ref.getDownloadURL();
      await _db.collection('businesses').doc(businessId).update({
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

  // Keep your existing updateBusinessData for generic map updates
  Future<void> updateBusinessData({
    required String businessId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection('businesses').doc(businessId).update(data);
    } catch (e) {
      throw Exception("Failed to update business: $e");
    }
  }

  // Getters

  Future<BusinessModel?> getBusiness(String businessId) async {
    final doc = await _db.collection('businesses').doc(businessId).get();
    if (!doc.exists) return null;
    return BusinessModel.fromMap(doc.data()!, doc.id);
  }

  Stream<BusinessModel?> getBusinessStream(String businessId) {
    return _db
        .collection('businesses')
        .doc(businessId)
        .snapshots()
        .map(
          (doc) =>
              doc.exists ? BusinessModel.fromMap(doc.data()!, doc.id) : null,
        );
  }

  Future<BusinessModel?> getMyBusiness(String ownerId) async {
    final query = await _db
        .collection('businesses')
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return BusinessModel.fromMap(query.docs.first.data(), query.docs.first.id);
  }

  Stream<List<BusinessModel>> getAllBusinesses() {
    return _db
        .collection('businesses')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => BusinessModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
