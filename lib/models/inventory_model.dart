class InventoryModel {
  final String id;
  final String organizerId; // Links to OrganizerModel
  final String rewardId; // Links to RewardModel
  final String name; // Copy of reward name for faster UI
  final int points; // Organizer-specific points
  final int stock; // Organizer-specific stock
  final bool isAvailable;

  InventoryModel({
    required this.id,
    required this.organizerId,
    required this.rewardId,
    required this.name,
    required this.points,
    required this.stock,
    this.isAvailable = true,
  });

  // Calculated Status
  String get statusText => stock <= 0 ? "Out of Stock" : "In Stock ($stock)";

  factory InventoryModel.fromMap(Map<String, dynamic> data, String id) {
    return InventoryModel(
      id: id,
      organizerId: data['organizerId'] ?? '',
      rewardId: data['rewardId'] ?? '',
      name: data['name'] ?? '',
      points: (data['points'] ?? 0) is int
          ? data['points'] as int
          : (data['points'] as num?)?.toInt() ?? 0,
      stock: (data['stock'] ?? 0) is int
          ? data['stock'] as int
          : (data['stock'] as num?)?.toInt() ?? 0,
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizerId': organizerId,
      'rewardId': rewardId,
      'name': name,
      'points': points,
      'stock': stock,
      'isAvailable': isAvailable,
    };
  }
}
