import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';
import '../models/reward_item_model.dart';

class CartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //References

  CollectionReference<Map<String, dynamic>> get _carts =>
      _db.collection('carts');

  //Stream: all cart docs for a user

  Stream<List<CartItemModel>> getCartsByUser(String userId) {
    return _carts
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CartItemModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  //Stream: single cart doc

  Stream<CartItemModel?> getCartStream(String cartId) {
    return _carts.doc(cartId).snapshots().map(
          (doc) => doc.exists
              ? CartItemModel.fromMap(doc.data()!, doc.id)
              : null,
        );
  }

  //Find existing cart for user + Organizer

  Future<CartItemModel?> findCart(String userId, String organizerId) async {
    final snap = await _carts
        .where('userId', isEqualTo: userId)
        .where('organizerId', isEqualTo: organizerId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return CartItemModel.fromMap(doc.data(), doc.id);
  }

  //Add / update a reward in the cart

  /// Adds [quantity] of [reward] to the user's cart for [OrganizerId].
  /// Creates the cart document if it doesn't exist yet.
  Future<void> addToCart({
    required String userId,
    required String organizerId,
    required RewardModel reward,
    required int quantity,
  }) async {
    // 1. Fetch latest stock to ensure we don't exceed it
    // We fetch all rewards for this organizer to accurately calculate effective stock (bundles/promos)
    final allRewardsSnap = await _db.collection('rewards')
        .where('organizerId', isEqualTo: organizerId)
        .get();
    
    final allRewards = allRewardsSnap.docs
        .map((doc) => RewardModel.fromMap(doc.data(), doc.id))
        .toList();

    final latestReward = allRewards.firstWhere(
      (p) => p.id == reward.id,
      orElse: () => throw Exception('Reward not found'),
    );
    
    final latestStock = latestReward.calculateEffectiveStock(allRewards);

    // Look for an existing cart for this user + Organizer
    var cart = await findCart(userId, organizerId);

    if (cart == null) {
      if (quantity > latestStock) {
        throw Exception('Only $latestStock items left in stock.');
      }

      // Create a new cart doc
      final rewards = {reward.id: quantity};
      final points = reward.points * quantity;

      await _carts.add({
        'userId': userId,
        'organizerId': organizerId,
        'rewards': rewards,
        'points': points,
      });
    } else {
      // Update existing cart
      final updatedRewards = Map<String, int>.from(cart.rewards);
      final currentInCart = updatedRewards[reward.id] ?? 0;
      final newTotalQuantity = currentInCart + quantity;

      if (newTotalQuantity > latestStock) {
        throw Exception('Only $latestStock items left in stock. You already have $currentInCart in your cart.');
      }

      updatedRewards[reward.id] = newTotalQuantity;

      // Recalculate total points
      final newPoints = await _recalculatePoints(updatedRewards);

      await _carts.doc(cart.id).update({
        'rewards': updatedRewards,
        'points': newPoints,
      });
    }
  }

  //Update quantity for a specific reward

  Future<void> updateRewardQuantity({
    required String cartId,
    required String rewardId,
    required int newQuantity,
    required Map<String, int> currentRewards,
  }) async {
    final updated = Map<String, int>.from(currentRewards);

    if (newQuantity <= 0) {
      updated.remove(rewardId);
    } else {
      // Check stock before updating
      final rewardDoc = await _db.collection('rewards').doc(rewardId).get();
      if (rewardDoc.exists) {
        final organizerId = rewardDoc.data()!['organizerId'];
        final allRewardsSnap = await _db.collection('rewards')
            .where('organizerId', isEqualTo: organizerId)
            .get();
        
        final allRewards = allRewardsSnap.docs
            .map((doc) => RewardModel.fromMap(doc.data(), doc.id))
            .toList();

        final latestReward = allRewards.firstWhere((p) => p.id == rewardId);
        final stock = latestReward.calculateEffectiveStock(allRewards);
        
        if (newQuantity > stock) {
          throw Exception('Only $stock items left in stock.');
        }
      }
      updated[rewardId] = newQuantity;
    }

    //If no rewards left, delete the cart doc
    if (updated.isEmpty) {
      await _carts.doc(cartId).delete();
      return;
    }

    final newPoints = await _recalculatePoints(updated);

    await _carts.doc(cartId).update({
      'rewards': updated,
      'points': newPoints,
    });
  }

  //Remove a reward from the cart

  Future<void> removeReward({
    required String cartId,
    required String rewardId,
    required Map<String, int> currentRewards,
  }) async {
    return updateRewardQuantity(
      cartId: cartId,
      rewardId: rewardId,
      newQuantity: 0,
      currentRewards: currentRewards,
    );
  }

  //Delete entire cart

  Future<void> deleteCart(String cartId) async {
    await _carts.doc(cartId).delete();
  }

  //Clear all carts for a user

  Future<void> clearAllCarts(String userId) async {
    final snap = await _carts.where('userId', isEqualTo: userId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  //Enrich a cart with reward names / images / points

  Future<CartItemModel> enrichCart(CartItemModel cart) async {
    final List<CartLineItem> lineItems = [];

    for (final entry in cart.rewards.entries) {
      final rewardId = entry.key;
      final qty = entry.value;

      final doc = await _db.collection('rewards').doc(rewardId).get();
      if (doc.exists) {
        final reward = RewardModel.fromMap(doc.data()!, doc.id);
        lineItems.add(CartLineItem(
          rewardId: rewardId,
          name: reward.name,
          imageUrl: reward.imageUrl,
          quantity: qty,
          unitPoints: reward.points,
        ));
      }
    }

    return cart.copyWithLineItems(lineItems);
  }

  //Helpers

  /// Fetches current reward points and recalculates the total.
  Future<int> _recalculatePoints(Map<String, int> rewards) async {
    int total = 0;
    for (final entry in rewards.entries) {
      final doc = await _db.collection('rewards').doc(entry.key).get();
      if (doc.exists) {
        final points = (doc.data()!['points'] as num?)?.toInt() ?? 0;
        total += points * entry.value;
      }
    }
    return total;
  }
}
