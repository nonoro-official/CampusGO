import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_model.dart';

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a specific item to a shop's shelf
  Future<void> addItemToInventory(InventoryModel item) async {
    await _db.collection('inventory').doc(item.id).set(item.toMap());
  }

  // Get all items for ONE specific shop (the "Menu")
  Stream<List<InventoryModel>> getShopInventory(String organizerId) {
    return _db
        .collection('inventory')
        .where('organizerId', isEqualTo: organizerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InventoryModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Update stock when something is sold
  Future<void> updateStock(String itemId, int newStock) async {
    await _db.collection('inventory').doc(itemId).update({'stock': newStock});
  }
}
