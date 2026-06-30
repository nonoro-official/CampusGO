import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/redemption_order_model.dart';
import '../models/reward_item_model.dart';
import '../models/enums.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Create ─────────────────────────────────────────────────────────────────

  /// Place a new order and decrease product stock. [orders] is a map of productId → quantity.
  Future<String> placeOrder({
    required String OrganizerId,
    required String userId,
    required Map<String, int> orders,
    required double price,
  }) async {
    final orderRef = _db.collection('orders').doc();

    // Generate an order number
    final now = DateTime.now();
    final orderNumber = 'ORD-${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    // 0. Resolve what to deduct by fetching the Organizer's current product map.
    // This allows us to handle Promos, Discounts, and Bundles by mapping them to their base items.
    final allProductsSnap = await _db.collection('products')
        .where('OrganizerId', isEqualTo: OrganizerId)
        .get();
    final allProducts = allProductsSnap.docs
        .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
        .toList();

    await _db.runTransaction((transaction) async {
      final Map<String, int> deductions = {}; // productId -> total quantity to subtract

      for (final entry in orders.entries) {
        final productId = entry.key;
        final qtyOrdered = entry.value;

        final product = allProducts.firstWhere(
          (p) => p.id == productId,
          orElse: () => throw Exception('Product $productId not found.'),
        );

        if (product.type == ListingType.promo && product.linkedProductId != null) {
          // Promo: deduct (qty * factor) from linked base product
          final factor = product.promoQuantity ?? 1;
          deductions[product.linkedProductId!] = (deductions[product.linkedProductId!] ?? 0) + (qtyOrdered * factor);
        } else if (product.type == ListingType.discount && product.linkedProductId != null) {
          // Linked Discount: deduct from base product
          deductions[product.linkedProductId!] = (deductions[product.linkedProductId!] ?? 0) + qtyOrdered;
        } else if (product.type == ListingType.bundle && product.bundleItems != null) {
          // Bundle: deduct 1 of each component per bundle unit
          for (final itemName in product.bundleItems!) {
            final component = allProducts.firstWhere(
              (p) => p.name == itemName && (p.type == ListingType.regular || (p.type == ListingType.discount && p.linkedProductId == null)),
              orElse: () => throw Exception('Bundle component "$itemName" not found.'),
            );
            deductions[component.id] = (deductions[component.id] ?? 0) + qtyOrdered;
          }
        } else {
          // Regular or non-linked: deduct from itself
          deductions[product.id] = (deductions[product.id] ?? 0) + qtyOrdered;
        }
      }

      // 1. PERFORM ALL READS FIRST (fetch current stock for target documents)
      final List<DocumentSnapshot> targetDocs = [];
      final List<String> targetIds = deductions.keys.toList();
      
      for (final id in targetIds) {
        final doc = await transaction.get(_db.collection('products').doc(id));
        if (!doc.exists) throw Exception('Stock item $id not found.');
        targetDocs.add(doc);
      }

      // 2. CHECK STOCK AND UPDATE
      for (int i = 0; i < targetDocs.length; i++) {
        final doc = targetDocs[i];
        final id = targetIds[i];
        final amountToDeduct = deductions[id]!;
        
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final currentStock = (data['stock'] ?? 0) is int
            ? data['stock'] as int
            : int.tryParse(data['stock']?.toString() ?? '0') ?? 0;

        if (currentStock < amountToDeduct) {
          throw Exception(
            'Insufficient stock for ${data['name'] ?? id}. Available: $currentStock',
          );
        }

        transaction.update(doc.reference, {'stock': currentStock - amountToDeduct});
      }

      // Create the order document
      transaction.set(orderRef, {
        'OrganizerId': OrganizerId,
        'userId': userId,
        'orders': orders,
        'price': price,
        'orderStatus': OrderStatus.processing.name,
        'timestamp': FieldValue.serverTimestamp(),
        'orderNumber': orderNumber,
      });
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

    final String OrganizerId = orderData['OrganizerId'];
    
    // Fetch all products for this Organizer to resolve what to restore
    final allProductsSnap = await _db.collection('products')
        .where('OrganizerId', isEqualTo: OrganizerId)
        .get();
    final allProducts = allProductsSnap.docs
        .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
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
        final productId = entry.key;
        final qtyOrdered = entry.value;

        final product = allProducts.firstWhere(
          (p) => p.id == productId,
          orElse: () => throw Exception('Product $productId not found.'),
        );

        if (product.type == ListingType.promo && product.linkedProductId != null) {
          final factor = product.promoQuantity ?? 1;
          additions[product.linkedProductId!] = (additions[product.linkedProductId!] ?? 0) + (qtyOrdered * factor);
        } else if (product.type == ListingType.discount && product.linkedProductId != null) {
          additions[product.linkedProductId!] = (additions[product.linkedProductId!] ?? 0) + qtyOrdered;
        } else if (product.type == ListingType.bundle && product.bundleItems != null) {
          for (final itemName in product.bundleItems!) {
            final component = allProducts.firstWhere(
              (p) => p.name == itemName && (p.type == ListingType.regular || (p.type == ListingType.discount && p.linkedProductId == null)),
              orElse: () => throw Exception('Bundle component "$itemName" not found.'),
            );
            additions[component.id] = (additions[component.id] ?? 0) + qtyOrdered;
          }
        } else {
          additions[product.id] = (additions[product.id] ?? 0) + qtyOrdered;
        }
      }

      // 1. Perform Reads for stock updates
      final List<DocumentSnapshot> targetDocs = [];
      final List<String> targetIds = additions.keys.toList();
      
      for (final id in targetIds) {
        final doc = await transaction.get(_db.collection('products').doc(id));
        targetDocs.add(doc);
      }

      // 2. Perform Updates
      for (int i = 0; i < targetDocs.length; i++) {
        final doc = targetDocs[i];
        if (!doc.exists) continue;
        
        final id = targetIds[i];
        final amountToAdd = additions[id]!;
        
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final currentStock = (data['stock'] ?? 0) is int
            ? data['stock'] as int
            : int.tryParse(data['stock']?.toString() ?? '0') ?? 0;

        transaction.update(doc.reference, {'stock': currentStock + amountToAdd});
      }

      // Finally, update order status
      transaction.update(txOrderDoc.reference, {'orderStatus': status.name});
    });
  }

  // ─── Streams ─────────────────────────────────────────────────────────────────

  /// All orders for a Organizer (vendor side) — real-time
  Stream<List<OrderModel>> getOrdersByOrganizer(String OrganizerId) {
    return _db
        .collection('orders')
        .where('OrganizerId', isEqualTo: OrganizerId)
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

  /// Fetches product details for every productId inside [order.orders] and
  /// returns the order with an enriched [items] list.
  Future<OrderModel> enrichOrder(OrderModel order) async {
    final List<OrderItemModel> items = [];

    for (final entry in order.orders.entries) {
      final productId = entry.key;
      final qty = entry.value;

      final doc = await _db.collection('products').doc(productId).get();
      if (doc.exists) {
        final product = ProductModel.fromMap(doc.data()!, doc.id);
        items.add(
          OrderItemModel(
            productId: productId,
            name: product.name,
            imageUrl: product.imageUrl,
            quantity: qty,
            price: product.price,
          ),
        );
      }
    }

    return order.copyWithItems(items);
  }
}
