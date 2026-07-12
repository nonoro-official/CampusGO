// ─── Enriched line-item (client-side only, for UI display) ───────────────────

class CartLineItem {
  final String rewardId;
  final String name;
  final String? imageUrl;
  final int quantity;
  final int unitPoints;

  int get total => unitPoints * quantity;

  const CartLineItem({
    required this.rewardId,
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

  ///Map of rewardId → quantity
  final Map<String, int> rewards;

  ///Total points (sum of unit points × qty for every reward)
  final int points;

  ///Enriched line-items — populated client-side after fetching reward info
  final List<CartLineItem> lineItems;

  int get totalQty => rewards.values.fold(0, (sum, qty) => sum + qty);

  CartItemModel({
    required this.id,
    required this.organizerId,
    required this.userId,
    required this.rewards,
    required this.points,
    this.lineItems = const [],
  });

  //Firestore -> Model

  factory CartItemModel.fromMap(Map<String, dynamic> data, String id) {
    final rawRewards = data['rewards'];
    final Map<String, int> rewardsMap = {};
    if (rawRewards is Map) {
      rawRewards.forEach((key, value) {
        rewardsMap[key.toString()] =
            value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }

    return CartItemModel(
      id: id,
      organizerId: data['organizerId'] ?? '',
      userId: data['userId'] ?? '',
      rewards: rewardsMap,
      points: (data['points'] as num?)?.toInt() ?? 0,
    );
  }

  //Model -> Firestore

  Map<String, dynamic> toMap() {
    return {
      'organizerId': organizerId,
      'userId': userId,
      'rewards': rewards,
      'points': points,
    };
  }

  CartItemModel copyWith({
    Map<String, int>? rewards,
    int? points,
    List<CartLineItem>? lineItems,
  }) {
    return CartItemModel(
      id: id,
      organizerId: organizerId,
      userId: userId,
      rewards: rewards ?? this.rewards,
      points: points ?? this.points,
      lineItems: lineItems ?? this.lineItems,
    );
  }

  CartItemModel copyWithLineItems(List<CartLineItem> lineItems) {
    return CartItemModel(
      id: id,
      organizerId: organizerId,
      userId: userId,
      rewards: rewards,
      points: points,
      lineItems: lineItems,
    );
  }
}
