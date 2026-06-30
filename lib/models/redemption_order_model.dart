import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Order Status ────────────────────────────────────────────────────────────

enum OrderStatus {
  processing,
  readyForPickup,
  completed,
  cancelled;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.processing,
    );
  }

  String get toName {
    switch (this) {
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// ─── Order Item ──────────────────────────────────────────────────────────────

class OrderItemModel {
  final String productId;
  final String name;
  final String? imageUrl;
  final int quantity;
  final double price;

  double get total => price * quantity;

  OrderItemModel({
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> data) {
    return OrderItemModel(
      productId: data['productId'] ?? '',
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'],
      quantity: (data['quantity'] ?? 1) is int
          ? data['quantity']
          : int.tryParse(data['quantity']?.toString() ?? '1') ?? 1,
      price: (data['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'price': price,
    };
  }
}

// ─── Order ───────────────────────────────────────────────────────────────────

class OrderModel {
  final String id;
  final String organizerId;
  final String userId;

  /// Map of productId → quantity  (the raw "orders" field from Firestore)
  final Map<String, int> orders;

  final DateTime timestamp;
  final OrderStatus orderStatus;
  final double price; // total price (subtotal + fees)

  /// Enriched line-items — populated client-side after fetching product names
  final List<OrderItemModel> items;

  final String? orderNumber; // human-friendly order number (optional)

  int get totalQty => orders.values.fold(0, (sum, qty) => sum + qty);

  OrderModel({
    required this.id,
    required this.organizerId,
    required this.userId,
    required this.orders,
    required this.timestamp,
    required this.orderStatus,
    required this.price,
    this.items = const [],
    this.orderNumber,
  });

  factory OrderModel.fromMap(Map<String, dynamic> data, String id) {
    // Parse the orders map (productId → quantity)
    final rawOrders = data['orders'];
    final Map<String, int> ordersMap = {};
    if (rawOrders is Map) {
      rawOrders.forEach((key, value) {
        ordersMap[key.toString()] = value is int
            ? value
            : int.tryParse(value.toString()) ?? 0;
      });
    }

    // Parse items list if it was stored (optional enriched copy)
    final rawItems = data['items'];
    final List<OrderItemModel> items = [];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(OrderItemModel.fromMap(item));
        }
      }
    }

    // Parse timestamp
    DateTime ts;
    if (data['timestamp'] is Timestamp) {
      ts = (data['timestamp'] as Timestamp).toDate();
    } else {
      ts =
          DateTime.tryParse(data['timestamp']?.toString() ?? '') ??
          DateTime.now();
    }

    return OrderModel(
      id: id,
      organizerId: data['organizerId'] ?? '',
      userId: data['userId'] ?? '',
      orders: ordersMap,
      timestamp: ts,
      orderStatus: OrderStatus.fromString(data['orderStatus'] ?? ''),
      price: (data['price'] ?? 0).toDouble(),
      items: items,
      orderNumber: data['orderNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizerId': organizerId,
      'userId': userId,
      'orders': orders,
      'timestamp': Timestamp.fromDate(timestamp),
      'orderStatus': orderStatus.name,
      'price': price,
      if (orderNumber != null) 'orderNumber': orderNumber,
    };
  }

  /// Returns a copy with enriched [items]
  OrderModel copyWithItems(List<OrderItemModel> items) {
    return OrderModel(
      id: id,
      organizerId: organizerId,
      userId: userId,
      orders: orders,
      timestamp: timestamp,
      orderStatus: orderStatus,
      price: price,
      items: items,
      orderNumber: orderNumber,
    );
  }

  /// Returns a copy with a new status
  OrderModel copyWithStatus(OrderStatus status) {
    return OrderModel(
      id: id,
      organizerId: organizerId,
      userId: userId,
      orders: orders,
      timestamp: timestamp,
      orderStatus: status,
      price: price,
      items: items,
      orderNumber: orderNumber,
    );
  }
}
