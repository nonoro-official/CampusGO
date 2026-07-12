import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import '../models/reward_item_model.dart';
import '../models/enums.dart';

class RewardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Search the global catalog (e.g., for a organizer adding items)
  Future<List<RewardModel>> searchGlobalRewards(String query) async {
    final snap = await _db
        .collection('rewards')
        .where('name', isGreaterThanOrEqualTo: query)
        .get();

    return snap.docs
        .map((doc) => RewardModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Get all rewards for a specific organizer/Organizer
  Stream<List<RewardModel>> getOrganizerRewardsStream(String organizerId) {
    return _db
        .collection('rewards')
        .where('organizerId', isEqualTo: organizerId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RewardModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Create a new reward for a organizer
  Future<String> createOrganizerReward({
    required String organizerId,
    required String name,
    required String description,
    required int points,
    String? imageUrl,
    ListingType type = ListingType.regular,
    int stock = 0,
    bool isAvailable = true,
    List<String>? bundleItems,
    int? promoQuantity,
    int? originalPoints,
    double? discountPercentage,
    String? linkedRewardId,
    required String sku,
    required List<String> categories,
    required String supplier,
  }) async {
    final ref = await _db.collection('rewards').add({
      'organizerId': organizerId,
      'name': name,
      'description': description,
      'points': points,
      'imageUrl': imageUrl,
      'stock': stock,
      'type': type.name,
      'isAvailable': isAvailable,
      'bundleItems': bundleItems,
      'promoQuantity': promoQuantity,
      'originalPoints': originalPoints,
      'discountPercentage': discountPercentage,
      'linkedRewardId': linkedRewardId,
      'sku': sku,
      'categories': categories,
      'supplier': supplier,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // Create a new "Master Reward" (for unique items)
  Future<String> createReward(RewardModel reward) async {
    final ref = await _db.collection('rewards').add(reward.toMap());
    return ref.id;
  }

  // Update an existing reward
  Future<void> updateOrganizerReward({
    required String rewardId,
    required String OrganizerId,
    required String name,
    String? description,
    required int points,
    String? imageUrl,
    ListingType? type,
    bool? isAvailable,
    List<String>? bundleItems,
    int? promoQuantity,
    int? stock,
    int? originalPoints,
    double? discountPercentage,
    String? linkedRewardId,
    required String sku,
    required List<String> categories,
    required String supplier,
  }) async {
    final updateData = <String, dynamic>{
      'name': name,
      'points': points,
      'sku': sku,
      'categories': categories,
      'supplier': supplier,
      'updatedAt': FieldValue.serverTimestamp(),
      'originalPoints': originalPoints, // Allow null to clear discount
      'discountPercentage': discountPercentage, // Allow null to clear discount
    };

    if (description != null) updateData['description'] = description;
    if (imageUrl != null) updateData['imageUrl'] = imageUrl;
    if (type != null) updateData['type'] = type.name;
    if (isAvailable != null) updateData['isAvailable'] = isAvailable;
    if (bundleItems != null) updateData['bundleItems'] = bundleItems;
    if (promoQuantity != null) updateData['promoQuantity'] = promoQuantity;
    if (stock != null) updateData['stock'] = stock;
    if (linkedRewardId != null) updateData['linkedRewardId'] = linkedRewardId;

    await _db.collection('rewards').doc(rewardId).update(updateData);
  }

  // Delete a reward
  Future<void> deleteOrganizerReward(String rewardId) async {
    await _db.collection('rewards').doc(rewardId).delete();
  }

  // Update stock
  Future<void> updateStock({
    required String rewardId,
    required int newStock,
  }) async {
    await _db.collection('rewards').doc(rewardId).update({
      'stock': newStock,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove a category from all rewards of a Organizer
  Future<void> removeCategoryFromOrganizer(String organizerId, String category) async {
    final query = _db.collection('rewards')
        .where('organizerId', isEqualTo: organizerId)
        .where('categories', arrayContains: category);
    
    final snap = await query.get();
    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {
        'categories': FieldValue.arrayRemove([category])
      });
    }
    
    await batch.commit();
  }

  // Upload reward image to Firebase Storage
  Future<String> uploadRewardImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() + p.extension(imageFile.path);
      Reference ref = _storage.ref().child('reward_images').child(fileName);
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    }
  }
}
