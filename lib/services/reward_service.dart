import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import '../models/reward_item_model.dart';
import '../models/enums.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Search the global catalog (e.g., for a organizer adding items)
  Future<List<ProductModel>> searchGlobalProducts(String query) async {
    final snap = await _db
        .collection('products')
        .where('name', isGreaterThanOrEqualTo: query)
        .get();

    return snap.docs
        .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Get all products for a specific organizer/Organizer
  Stream<List<ProductModel>> getOrganizerProductsStream(String organizerId) {
    return _db
        .collection('products')
        .where('organizerId', isEqualTo: organizerId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Create a new product for a organizer
  Future<String> createOrganizerProduct({
    required String organizerId,
    required String name,
    required String description,
    required double price,
    String? imageUrl,
    ListingType type = ListingType.regular,
    int stock = 0,
    bool isAvailable = true,
    List<String>? bundleItems,
    int? promoQuantity,
    double? originalPrice,
    double? discountPercentage,
    String? linkedProductId,
    required String sku,
    required List<String> categories,
    required String supplier,
  }) async {
    final ref = await _db.collection('products').add({
      'organizerId': organizerId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'stock': stock,
      'type': type.name,
      'isAvailable': isAvailable,
      'bundleItems': bundleItems,
      'promoQuantity': promoQuantity,
      'originalPrice': originalPrice,
      'discountPercentage': discountPercentage,
      'linkedProductId': linkedProductId,
      'sku': sku,
      'categories': categories,
      'supplier': supplier,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // Create a new "Master Product" (for unique items)
  Future<String> createProduct(ProductModel product) async {
    final ref = await _db.collection('products').add(product.toMap());
    return ref.id;
  }

  // Update an existing product
  Future<void> updateOrganizerProduct({
    required String productId,
    required String OrganizerId,
    required String name,
    String? description,
    required double price,
    String? imageUrl,
    ListingType? type,
    bool? isAvailable,
    List<String>? bundleItems,
    int? promoQuantity,
    double? originalPrice,
    double? discountPercentage,
    int? stock,
    String? linkedProductId,
    required String sku,
    required List<String> categories,
    required String supplier,
  }) async {
    final updateData = <String, dynamic>{
      'name': name,
      'price': price,
      'sku': sku,
      'categories': categories,
      'supplier': supplier,
      'updatedAt': FieldValue.serverTimestamp(),
      'originalPrice': originalPrice, // Allow null to clear discount
      'discountPercentage': discountPercentage, // Allow null to clear discount
    };

    if (description != null) updateData['description'] = description;
    if (imageUrl != null) updateData['imageUrl'] = imageUrl;
    if (type != null) updateData['type'] = type.name;
    if (isAvailable != null) updateData['isAvailable'] = isAvailable;
    if (bundleItems != null) updateData['bundleItems'] = bundleItems;
    if (promoQuantity != null) updateData['promoQuantity'] = promoQuantity;
    if (stock != null) updateData['stock'] = stock;
    if (linkedProductId != null) updateData['linkedProductId'] = linkedProductId;

    await _db.collection('products').doc(productId).update(updateData);
  }

  // Delete a product
  Future<void> deleteOrganizerProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  // Update stock
  Future<void> updateStock({
    required String productId,
    required int newStock,
  }) async {
    await _db.collection('products').doc(productId).update({
      'stock': newStock,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove a category from all products of a Organizer
  Future<void> removeCategoryFromOrganizer(String organizerId, String category) async {
    final query = _db.collection('products')
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

  // Upload product image to Firebase Storage
  Future<String> uploadProductImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() + p.extension(imageFile.path);
      Reference ref = _storage.ref().child('product_images').child(fileName);
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    }
  }
}
