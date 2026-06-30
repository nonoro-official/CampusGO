class InventoryModel {
  final String id;
  final String businessId; // Links to BusinessModel
  final String productId; // Links to ProductModel
  final String name; // Copy of product name for faster UI
  final double price; // Vendor-specific price
  final int stock; // Vendor-specific stock
  final bool isAvailable;

  InventoryModel({
    required this.id,
    required this.businessId,
    required this.productId,
    required this.name,
    required this.price,
    required this.stock,
    this.isAvailable = true,
  });

  // Calculated Status
  String get statusText => stock <= 0 ? "Out of Stock" : "In Stock ($stock)";

  factory InventoryModel.fromMap(Map<String, dynamic> data, String id) {
    return InventoryModel(
      id: id,
      businessId: data['businessId'] ?? '',
      productId: data['productId'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      stock: (data['stock'] ?? 0).toInt(),
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'productId': productId,
      'name': name,
      'price': price,
      'stock': stock,
      'isAvailable': isAvailable,
    };
  }
}
