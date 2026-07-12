import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/redemption_order_model.dart';
import '../models/reward_item_model.dart';
import '../models/enums.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Create ─────────────────────────────────────────────────────────────────

  /// Place a new order and decrease reward stock. [orders] is a map of rewardId → quantity.
  Future<String> placeOrder({
    required String organizerId,
    required String userId,
    required Map<String, int> orders,
    required int points,
  }) async {
    final orderRef = _db.collection('orders').doc();

    // Generate an order number
    final now = DateTime.now();
    final orderNumber = 'ORD-${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    // 0. Resolve what to deduct by fetching the Organizer's current reward map.
    // This allows us to handle Promos, Discounts, and Bundles by mapping them to their base items.
    final allRewardsSnap = await _db.collection('rewards')
        .where('organizerId', isEqualTo: organizerId)
        .get();
    final allRewards = allRewardsSnap.docs
        .map((doc) => RewardModel.fromMap(doc.data(), doc.id))
        .toList();

    await _db.runTransaction((transaction) async {
      // --- POINT CHECK & DEDUCTION ---
      final userDocRef = _db.collection('users').doc(userId);
      final userSnap = await transaction.get(userDocRef);
      if (!userSnap.exists) throw Exception('User not found.');

      final userData = userSnap.data() as Map<String, dynamic>;
      final currentPoints = (userData['points'] as num?)?.toInt() ?? 0;

      if (currentPoints < points) {
        throw Exception(
          'Insufficient points. You have $currentPoints pts, but this order requires $points pts.',
        );
      }

      final Map<String, int> deductions = {}; // rewardId -> total quantity to subtract

      for (final entry in orders.entries) {
        final rewardId = entry.key;
        final qtyOrdered = entry.value;

        final reward = allRewards.firstWhere(
          (p) => p.id == rewardId,
          orElse: () => throw Exception('Reward $rewardId not found.'),
        );

        if (reward.type == ListingType.promo && reward.linkedRewardId != null) {
          // Promo: deduct (qty * factor) from linked base reward
          final factor = reward.promoQuantity ?? 1;
          deductions[reward.linkedRewardId!] = (deductions[reward.linkedRewardId!] ?? 0) + (qtyOrdered * factor);
        } else if (reward.type == ListingType.discount && reward.linkedRewardId != null) {
          // Linked Discount: deduct from base reward
          deductions[reward.linkedRewardId!] = (deductions[reward.linkedRewardId!] ?? 0) + qtyOrdered;
        } else if (reward.type == ListingType.bundle && reward.bundleItems != null) {
          // Bundle: deduct 1 of each component per bundle unit
          for (final itemName in reward.bundleItems!) {
            final component = allRewards.firstWhere(
              (p) => p.name == itemName && (p.type == ListingType.regular || (p.type == ListingType.discount && p.linkedRewardId == null)),
              orElse: () => throw Exception('Bundle component "$itemName" not found.'),
            );
            deductions[component.id] = (deductions[component.id] ?? 0) + qtyOrdered;
          }
        } else {
          // Regular or non-linked: deduct from itself
          deductions[reward.id] = (deductions[reward.id] ?? 0) + qtyOrdered;
        }
      }

      // 1. PERFORM ALL READS FIRST (fetch current stock for target documents)
      final List<DocumentSnapshot> targetDocs = [];
      final List<String> targetIds = deductions.keys.toList();
      
      for (final id in targetIds) {
        final doc = await transaction.get(_db.collection('rewards').doc(id));
        if (!doc.exists) throw Exception('Stock item $id not found.');
        targetDocs.add(doc);
      }

      // 2. CHECK STOCK AND UPDATE
      for (int i = 0; i < targetDocs.length; i++) {
        final doc = targetDocs[i];
        final id = targetIds[i];
        final amountToDeduct = deductions[id]!;
        
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final currentStock = (data['stock'] as num?)?.toInt() ?? 0;

        if (currentStock < amountToDeduct) {
          throw Exception(
            'Insufficient stock for ${data['name'] ?? id}. Available: $currentStock',
          );
        }

        transaction.update(doc.reference, {'stock': currentStock - amountToDeduct});
      }

      // Finally, create the order document and deduct user points
      transaction.set(orderRef, {
        'organizerId': organizerId,
        'userId': userId,
        'orders': orders,
        'points': points,
        'orderStatus': OrderStatus.processing.name,
        'timestamp': FieldValue.serverTimestamp(),
        'orderNumber': orderNumber,
      });

      transaction.update(userDocRef, {'points': currentPoints - points});
    });

    return orderRef.id;
  }

  // ─── Update Status ───────────────────────────────────────────────────────────

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    if (status != OrderStatus.cancelled) {
      await _db.collection('orders').doc(orderId).update({
        'orderStatus': status.name,
      });
      return;
    }

    // Handle Cancellation: Restore Stock
    // Fetch order first to get OrganizerId and orders map
    final orderDoc = await _db.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) throw Exception('Order not found.');
    final orderData = orderDoc.data()!;
    final currentStatus = OrderStatus.fromString(orderData['orderStatus'] ?? '');
    
    // If already cancelled, do nothing regarding stock
    if (currentStatus == OrderStatus.cancelled) return;

    final String organizerId = orderData['organizerId'];
    
    // Fetch all rewards for this Organizer to resolve what to restore
    final allRewardsSnap = await _db.collection('rewards')
        .where('organizerId', isEqualTo: organizerId)
        .get();
    final allRewards = allRewardsSnap.docs
        .map((doc) => RewardModel.fromMap(doc.data(), doc.id))
        .toList();

    await _db.runTransaction((transaction) async {
      // Re-read order status inside transaction to prevent race conditions
      final txOrderDoc = await transaction.get(_db.collection('orders').doc(orderId));
      if (!txOrderDoc.exists) return;
      final txOrderData = txOrderDoc.data() as Map<String, dynamic>;
      if (OrderStatus.fromString(txOrderData['orderStatus'] ?? '') == OrderStatus.cancelled) return;

      final Map<String, int> ordersMap = {};
      final rawOrders = txOrderData['orders'];
      if (rawOrders is Map) {
        rawOrders.forEach((key, value) {
          ordersMap[key.toString()] = value is int ? value : int.tryParse(value.toString()) ?? 0;
        });
      }

      final Map<String, int> additions = {};

      for (final entry in ordersMap.entries) {
        final rewardId = entry.key;
        final qtyOrdered = entry.value;

        final reward = allRewards.firstWhere(
          (p) => p.id == rewardId,
          orElse: () => throw Exception('Reward $rewardId not found.'),
        );

        if (reward.type == ListingType.promo && reward.linkedRewardId != null) {
          final factor = reward.promoQuantity ?? 1;
          additions[reward.linkedRewardId!] = (additions[reward.linkedRewardId!] ?? 0) + (qtyOrdered * factor);
        } else if (reward.type == ListingType.discount && reward.linkedRewardId != null) {
          additions[reward.linkedRewardId!] = (additions[reward.linkedRewardId!] ?? 0) + qtyOrdered;
        } else if (reward.type == ListingType.bundle && reward.bundleItems != null) {
          for (final itemName in reward.bundleItems!) {
            final component = allRewards.firstWhere(
              (p) => p.name == itemName && (p.type == ListingType.regular || (p.type == ListingType.discount && p.linkedRewardId == null)),
              orElse: () => throw Exception('Bundle component "$itemName" not found.'),
            );
            additions[component.id] = (additions[component.id] ?? 0) + qtyOrdered;
          }
        } else {
          additions[reward.id] = (additions[reward.id] ?? 0) + qtyOrdered;
        }
      }

      // 1. Perform Reads for stock updates
      final List<DocumentSnapshot> targetDocs = [];
      final List<String> targetIds = additions.keys.toList();
      
      for (final id in targetIds) {
        final doc = await transaction.get(_db.collection('rewards').doc(id));
        targetDocs.add(doc);
      }

      // 2. Perform Updates
      for (int i = 0; i < targetDocs.length; i++) {
        final doc = targetDocs[i];
        if (!doc.exists) continue;
        
        final id = targetIds[i];
        final amountToAdd = additions[id]!;
        
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final currentStock = (data['stock'] as num?)?.toInt() ?? 0;

        transaction.update(doc.reference, {'stock': currentStock + amountToAdd});
      }

      // Finally, update order status and restore points
      transaction.update(txOrderDoc.reference, {'orderStatus': status.name});

      final userDocRef = _db.collection('users').doc(txOrderData['userId']);
      final userSnap = await transaction.get(userDocRef);
      if (userSnap.exists) {
        final userData = userSnap.data() as Map<String, dynamic>;
        final currentPoints = (userData['points'] as num?)?.toInt() ?? 0;
        final orderPoints = (txOrderData['points'] as num?)?.toInt() ?? 0;
        transaction.update(userDocRef, {'points': currentPoints + orderPoints});
      }
    });
  }

  // ─── Streams ─────────────────────────────────────────────────────────────────

  /// All orders for a Organizer (organizer side) — real-time
  Stream<List<OrderModel>> getOrdersByOrganizer(String organizerId) {
    return _db
        .collection('orders')
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  /// All orders for a customer (customer side) — real-time
  Stream<List<OrderModel>> getOrdersByUser(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  /// Single order — real-time
  Stream<OrderModel?> getOrderStream(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map(
          (doc) => doc.exists ? OrderModel.fromMap(doc.data()!, doc.id) : null,
    );
  }

  // ─── Enrichment ──────────────────────────────────────────────────────────────

  /// Fetches reward details for every rewardId inside [order.orders] and
  /// returns the order with an enriched [items] list.
  Future<OrderModel> enrichOrder(OrderModel order) async {
    final List<OrderItemModel> items = [];

    for (final entry in order.orders.entries) {
      final rewardId = entry.key;
      final qty = entry.value;

      final doc = await _db.collection('rewards').doc(rewardId).get();
      if (doc.exists) {
        final reward = RewardModel.fromMap(doc.data()!, doc.id);
        items.add(
          OrderItemModel(
            rewardId: rewardId,
            name: reward.name,
            imageUrl: reward.imageUrl,
            quantity: qty,
            points: reward.points,
          ),
        );
      }
    }

    return order.copyWithItems(items);
  }
}
