import 'enums.dart';
import 'package:collection/collection.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final double price;
  final String businessId;
  final int stock; 
  final ListingType type;
  final bool isAvailable;
  
  final List<String>? bundleItems; 
  final int? promoQuantity;
  final double? originalPrice;
  final double? discountPercentage;
  final String? linkedProductId; 

  final String sku;
  final List<String> categories;
  final String supplier;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.price,
    required this.businessId,
    required this.stock,
    this.type = ListingType.regular,
    this.isAvailable = true,
    this.bundleItems,
    this.promoQuantity,
    this.originalPrice,
    this.discountPercentage,
    this.linkedProductId,
    required this.sku,
    required this.categories,
    required this.supplier,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Finds the "base" product that holds the physical stock for this listing.
  ProductModel? findBaseProduct(List<ProductModel> allProducts) {
    // A regular product is its own base.
    if (type == ListingType.regular) return this;

    // 1. Try to find by explicit ID link
    if (linkedProductId != null && linkedProductId!.isNotEmpty) {
      final base = allProducts.firstWhereOrNull((p) => p.id == linkedProductId);
      if (base != null) return base;
    }

    // 2. Try to find by Name (looking for a 'regular' listing that isn't itself)
    return allProducts.firstWhereOrNull(
      (p) => p.id != id && 
             p.name == name && 
             (p.type == ListingType.regular || (p.type == ListingType.discount && p.linkedProductId == null)),
    );
  }

  int calculateEffectiveStock(List<ProductModel> allProducts) {
    if (!isAvailable) return 0;
    
    // 1. Bundle Logic: Stock is the minimum stock of its components.
    if (type == ListingType.bundle && bundleItems != null && bundleItems!.isNotEmpty) {
      int minStock = -1;
      for (var itemName in bundleItems!) {
        // Look for the component (must be a regular item or unlinked discount)
        final item = allProducts.firstWhereOrNull(
          (p) => p.name == itemName && (p.type == ListingType.regular || (p.type == ListingType.discount && p.linkedProductId == null)),
        );
        
        if (item == null || !item.isAvailable) return 0; 
        
        if (minStock == -1 || item.stock < minStock) {
          minStock = item.stock;
        }
      }
      return minStock == -1 ? 0 : minStock;
    }

    // 2. Promo/Discount/Linked Logic
    final baseItem = findBaseProduct(allProducts);
    
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

  factory ProductModel.fromMap(Map<String, dynamic> data, String id) {
    List<String> categories = [];
    if (data['categories'] != null) {
      categories = List<String>.from(data['categories']);
    } else if (data['category'] != null && data['category'] is String) {
      categories = [data['category']];
    }

    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      price: (data['price'] ?? 0).toDouble(),
      businessId: data['businessId'] ?? '',
      stock: (data['stock'] ?? 0) is int
          ? data['stock'] ?? 0
          : int.tryParse(data['stock']?.toString() ?? '0') ?? 0,
      type: ListingType.fromString(data['type'] ?? 'regular'),
      isAvailable: data['isAvailable'] ?? true,
      bundleItems: data['bundleItems'] != null ? List<String>.from(data['bundleItems']) : null,
      promoQuantity: data['promoQuantity'],
      originalPrice: data['originalPrice'] != null ? (data['originalPrice'] as num).toDouble() : null,
      discountPercentage: data['discountPercentage'] != null ? (data['discountPercentage'] as num).toDouble() : null,
      linkedProductId: data['linkedProductId'],
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
      'price': price,
      'businessId': businessId,
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
    };
  }
}
