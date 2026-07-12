import 'enums.dart';
import 'package:collection/collection.dart';

class RewardModel {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final int points;
  final String organizerId;
  final int stock; 
  final ListingType type;
  final bool isAvailable;
  
  final List<String>? bundleItems; 
  final int? promoQuantity;
  final int? originalPoints;
  final double? discountPercentage;
  final String? linkedRewardId; 

  final String sku;
  final List<String> categories;
  final String supplier;

  RewardModel({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.points,
    required this.organizerId,
    required this.stock,
    this.type = ListingType.regular,
    this.isAvailable = true,
    this.bundleItems,
    this.promoQuantity,
    this.originalPoints,
    this.discountPercentage,
    this.linkedRewardId,
    required this.sku,
    required this.categories,
    required this.supplier,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Finds the "base" reward that holds the physical stock for this listing.
  RewardModel? findBaseReward(List<RewardModel> allRewards) {
    // A regular reward is its own base.
    if (type == ListingType.regular) return this;

    // 1. Try to find by explicit ID link
    if (linkedRewardId != null && linkedRewardId!.isNotEmpty) {
      final base = allRewards.firstWhereOrNull((p) => p.id == linkedRewardId);
      if (base != null) return base;
    }

    // 2. Try to find by Name (looking for a 'regular' listing that isn't itself)
    return allRewards.firstWhereOrNull(
      (p) => p.id != id && 
             p.name == name && 
             (p.type == ListingType.regular || (p.type == ListingType.discount && p.linkedRewardId == null)),
    );
  }

  int calculateEffectiveStock(List<RewardModel> allRewards) {
    if (!isAvailable) return 0;
    
    // 1. Bundle Logic: Stock is the minimum stock of its components.
    if (type == ListingType.bundle && bundleItems != null && bundleItems!.isNotEmpty) {
      int minStock = -1;
      for (var itemName in bundleItems!) {
        // Look for the component (must be a regular item or unlinked discount)
        final item = allRewards.firstWhereOrNull(
          (p) => p.name == itemName && (p.type == ListingType.regular || (p.type == ListingType.discount && p.linkedRewardId == null)),
        );
        
        if (item == null || !item.isAvailable) return 0; 
        
        if (minStock == -1 || item.stock < minStock) {
          minStock = item.stock;
        }
      }
      return minStock == -1 ? 0 : minStock;
    }

    // 2. Promo/Discount/Linked Logic
    final baseItem = findBaseReward(allRewards);
    
    // If no base item is found (other than itself), return its own stock.
    if (baseItem == null || baseItem.id == id) {
       return stock;
    }

    if (!baseItem.isAvailable) return 0;

    // 3. Promo Logic: Base stock divided by the total items per promo unit.
    if (type == ListingType.promo && promoQuantity != null && promoQuantity! > 0) {
      return baseItem.stock ~/ promoQuantity!;
    }

    // 4. Linked Discount: Use the base item's stock directly.
    return baseItem.stock;
  }

  factory RewardModel.fromMap(Map<String, dynamic> data, String id) {
    List<String> categories = [];
    if (data['categories'] != null) {
      categories = List<String>.from(data['categories']);
    } else if (data['category'] != null && data['category'] is String) {
      categories = [data['category']];
    }

    return RewardModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      points: (data['points'] as num?)?.toInt() ?? 0,
      organizerId: data['organizerId'] ?? '',
      stock: (data['stock'] ?? 0) is int
          ? data['stock'] ?? 0
          : int.tryParse(data['stock']?.toString() ?? '0') ?? 0,
      type: ListingType.fromString(data['type'] ?? 'regular'),
      isAvailable: data['isAvailable'] ?? true,
      bundleItems: data['bundleItems'] != null ? List<String>.from(data['bundleItems']) : null,
      promoQuantity: data['promoQuantity'],
      originalPoints: data['originalPoints'] != null ? (data['originalPoints'] as num).toInt() : null,
      discountPercentage: data['discountPercentage'] != null ? (data['discountPercentage'] as num).toDouble() : null,
      linkedRewardId: data['linkedRewardId'],
      sku: data['sku'] ?? '',
      categories: categories,
      supplier: data['supplier'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'points': points,
      'organizerId': organizerId,
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
    };
  }
}
