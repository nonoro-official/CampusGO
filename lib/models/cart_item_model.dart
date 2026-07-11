// ─── Enriched line-item (client-side only, for UI display) ───────────────────

class CartLineItem {
  final String productId;
  final String name;
  final String? imageUrl;
  final int quantity;
  final double unitPoints;

  double get total => unitPoints * quantity;

  const CartLineItem({
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.quantity,
    required this.unitPoints,
  });
}

//Cart document stored in Firestore

class CartItemModel {
  final String id;
  final String organizerId;
  final String userId;

  ///Map of productId → quantity
  final Map<String, int> products;

  ///Total points (sum of unit points × qty for every product)
  final double points;

  ///Enriched line-items — populated client-side after fetching product info
  final List<CartLineItem> lineItems;

  int get totalQty => products.values.fold(0, (sum, qty) => sum + qty);

  CartItemModel({
    required this.id,
    required this.organizerId,
    required this.userId,
    required this.products,
    required this.points,
    this.lineItems = const [],
  });

  //Firestore -> Model

  factory CartItemModel.fromMap(Map<String, dynamic> data, String id) {
    final rawProducts = data['products'];
    final Map<String, int> productsMap = {};
    if (rawProducts is Map) {
      rawProducts.forEach((key, value) {
        productsMap[key.toString()] =
            value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }

    return CartItemModel(
      id: id,
      organizerId: data['organizerId'] ?? '',
      userId: data['userId'] ?? '',
      products: productsMap,
      points: (data['points'] ?? 0).toDouble(),
    );
  }

  //Model -> Firestore

  Map<String, dynamic> toMap() {
    return {
      'organizerId': organizerId,
      'userId': userId,
      'products': products,
      'points': points,
    };
  }

  CartItemModel copyWith({
    Map<String, int>? products,
    double? points,
    List<CartLineItem>? lineItems,
  }) {
    return CartItemModel(
      id: id,
      organizerId: organizerId,
      userId: userId,
      products: products ?? this.products,
      points: points ?? this.points,
      lineItems: lineItems ?? this.lineItems,
    );
  }

  CartItemModel copyWithLineItems(List<CartLineItem> lineItems) {
    return CartItemModel(
      id: id,
      organizerId: organizerId,
      userId: userId,
      products: products,
      points: points,
      lineItems: lineItems,
    );
  }
}
