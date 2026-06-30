import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward_item_model.dart';
import '../services/product_service.dart';

final productServiceProvider = Provider<ProductService>(
  (ref) => ProductService(),
);

// Get products for a specific vendor (family provider)
final vendorProductsProvider =
    StreamProvider.family<List<ProductModel>, String>((ref, OrganizerId) {
      final productService = ref.watch(productServiceProvider);
      return productService.getVendorProductsStream(OrganizerId);
    });

// Get unique categories for a specific vendor
final vendorCategoriesProvider =
    Provider.family<AsyncValue<List<String>>, String>((ref, OrganizerId) {
  final productsAsync = ref.watch(vendorProductsProvider(OrganizerId));
  
  return productsAsync.whenData((products) {
    final categories = <String>{};
    for (final product in products) {
      categories.addAll(product.categories);
    }
    final sortedCategories = categories.toList()..sort();
    return sortedCategories;
  });
});
