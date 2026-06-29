import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/search.dart';
import '../widgets/filter.dart';
import '../widgets/top_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../models/product_model.dart';
import '../../../models/enums.dart';
import 'edit_listings.dart';

class ListingScreen extends ConsumerStatefulWidget {
  const ListingScreen({super.key});

  @override
  ConsumerState<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends ConsumerState<ListingScreen> {
  String selectedType = "All Types";
  String selectedCategory = "All Categories";
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: TopBar(
        title: 'Manage Listings',
        showBack: true,
        center: true,
        rightIcon: Icons.add,
        onRightPressed: () {
          if (user?.businessId != null) {
            showListingModal(
              context: context,
              ref: ref,
              businessId: user!.businessId!,
            );
          }
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     if (user?.businessId != null) {
      //       showListingModal(
      //         context: context,
      //         ref: ref,
      //         businessId: user!.businessId!,
      //       );
      //     }
      //   },
      //   child: const Icon(Icons.add),
      // ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.center,
                child: Text("Product Listings", style: textTheme.titleLarge),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SearchBarWidget(
                      onSearch: (val) => setState(() => searchQuery = val),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    flex: 2,
                    child: FilterWidget(
                      options: const [
                        "All Types",
                        "Regular",
                        "Bundle",
                        "Promo",
                        "Discount",
                      ],
                      selectedValue: selectedType,
                      onChanged: (val) => setState(() => selectedType = val!),
                    ),
                  ),
                ],
              ),
            ),

            if (user?.businessId != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _CategoryFilter(
                  businessId: user!.businessId!,
                  selectedCategory: selectedCategory,
                  onChanged: (val) => setState(() => selectedCategory = val!),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: InventoryList(
                  businessId: user.businessId!,
                  searchQuery: searchQuery,
                  selectedType: selectedType,
                  selectedCategory: selectedCategory,
                ),
              ),
            ] else
              const Expanded(child: Center(child: Text('No business found'))),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  final String businessId;
  final String selectedCategory;
  final ValueChanged<String?> onChanged;

  const _CategoryFilter({
    required this.businessId,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(vendorProductsProvider(businessId));

    return productsAsync.when(
      data: (products) {
        final categories = products
            .expand((p) => p.categories)
            .toSet()
            .toList();
        categories.sort();
        final displayCategories = ["All Categories", ...categories];

        return FilterWidget(
          options: displayCategories,
          selectedValue: selectedCategory,
          onChanged: onChanged,
        );
      },
      loading: () => const SizedBox(height: 45),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class InventoryList extends ConsumerWidget {
  final String businessId;
  final String searchQuery;
  final String selectedType;
  final String selectedCategory;

  const InventoryList({
    super.key,
    required this.businessId,
    required this.searchQuery,
    required this.selectedType,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(vendorProductsProvider(businessId));

    return productsAsync.when(
      data: (products) {
        final filteredProducts = products.where((product) {
          final query = searchQuery.toLowerCase();
          final matchesSearch =
              product.name.toLowerCase().contains(query) ||
              product.description.toLowerCase().contains(query) ||
              (product.sku.toLowerCase().contains(query)) ||
              (product.categories.any((c) => c.toLowerCase().contains(query)));

          final matchesType =
              selectedType == "All Types" ||
              product.type.toName == selectedType;

          final matchesCategory =
              selectedCategory == "All Categories" ||
              product.categories.contains(selectedCategory);

          return matchesSearch && matchesType && matchesCategory;
        }).toList();

        if (filteredProducts.isEmpty) {
          return const Center(child: Text("No products found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            return ListingCard(
              product: filteredProducts[index],
              allProducts: products,
            );
          },
        );
      },

      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class ListingCard extends ConsumerWidget {
  final ProductModel product;
  final List<ProductModel> allProducts;

  const ListingCard({
    super.key,
    required this.product,
    required this.allProducts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    int stock = product.calculateEffectiveStock(allProducts);

    // final isOutOfStock = stock <= 0;
    // final isLowStock = stock < 10 && stock > 0;

    // Color statusColor = !product.isAvailable || isOutOfStock
    //     ? Colors.red
    //     : isLowStock
    //     ? Colors.orange
    //     : Colors.green;

    // String statusText = !product.isAvailable
    //     ? "Unavailable"
    //     : (isOutOfStock
    //           ? "Out of Stock"
    //           : (isLowStock ? "Low Stock" : "In Stock"));

    // Color based on listing type
    Color typeColor;
    switch (product.type) {
      case ListingType.regular:
        typeColor = primaryColor;
        break;
      case ListingType.discount:
        typeColor = Colors.red;
        break;
      case ListingType.bundle:
        typeColor = Colors.deepPurple;
        break;
      case ListingType.promo:
        typeColor = Colors.orange.shade800;
        break;
    }

    return GestureDetector(
      onTap: () {
        showListingModal(
          context: context,
          ref: ref,
          businessId: product.businessId,
          product: product,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      _buildPriceInfo(context),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        product.type.toName,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _showDeleteDialog(context, ref),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),

            if (product.categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 4,
                  children: product.categories
                      .map(
                        (cat) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            cat,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 9,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            const SizedBox(height: 12),

            _buildListingDetails(context),

            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // if (product.type == ListingType.regular || (product.type == ListingType.discount && product.linkedProductId == null))
                //   Row(
                //     children: [
                //       _stockButton(
                //         icon: Icons.remove,
                //         onTap: () {
                //           if (product.stock > 0) {
                //             productService.updateStock(
                //               productId: product.id,
                //               newStock: product.stock - 1,
                //             );
                //           }
                //         },
                //       ),
                //       const SizedBox(width: 14),
                //       Text("$stock", style: textTheme.bodyLarge),
                //       const SizedBox(width: 14),
                //       _stockButton(
                //         icon: Icons.add,
                //         onTap: () {
                //           productService.updateStock(
                //             productId: product.id,
                //             newStock: product.stock + 1,
                //           );
                //         },
                //       ),
                //     ],
                //   )
                // else
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "$stock available",
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 14,
                //     vertical: 6,
                //   ),
                //   decoration: BoxDecoration(
                //     color: statusColor.withValues(alpha: 0.15),
                //     borderRadius: BorderRadius.circular(20),
                //   ),
                //   child: Text(
                //     statusText,
                //     style: TextStyle(
                //       color: statusColor,
                //       fontWeight: FontWeight.bold,
                //       fontSize: 12,
                //     ),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(productServiceProvider).deleteVendorProduct(product.id);
    }
  }

  Widget _buildPriceInfo(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    double? originalPrice = product.originalPrice;

    // Automatically calculate original price for bundles/promos if missing or not reflecting base items
    if (originalPrice == null || originalPrice <= product.price) {
      if (product.type == ListingType.bundle && product.bundleItems != null) {
        double total = 0;
        for (var itemName in product.bundleItems!) {
          final item = allProducts.firstWhereOrNull(
            (p) =>
                p.name == itemName &&
                (p.type == ListingType.regular ||
                    (p.type == ListingType.discount &&
                        p.linkedProductId == null)),
          );
          if (item != null) total += item.price;
        }
        if (total > product.price) originalPrice = total;
      } else if (product.type == ListingType.promo &&
          product.promoQuantity != null) {
        final baseItem = allProducts.firstWhereOrNull(
          (p) =>
              (product.linkedProductId != null
                  ? p.id == product.linkedProductId
                  : p.name == product.name) &&
              (p.type == ListingType.regular ||
                  (p.type == ListingType.discount &&
                      p.linkedProductId == null)),
        );
        if (baseItem != null) {
          double total = baseItem.price * product.promoQuantity!;
          if (total > product.price) originalPrice = total;
        }
      }
    }

    bool hasDiscount = originalPrice != null && originalPrice > product.price;

    if (hasDiscount) {
      double discountPercentage =
          product.discountPercentage ??
          ((1 - (product.price / originalPrice)) * 100);
      return Row(
        children: [
          Text(
            "₱${product.price.toStringAsFixed(2)}",
            style: textTheme.bodySmall?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "₱${originalPrice.toStringAsFixed(2)}",
            style: textTheme.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            ),
          ),
          if (discountPercentage > 0) ...[
            const SizedBox(width: 6),
            Text(
              "-${discountPercentage.toStringAsFixed(0)}%",
              style: const TextStyle(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      );
    }

    return Text(
      "₱${product.price.toStringAsFixed(2)}",
      style: textTheme.bodySmall?.copyWith(
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildListingDetails(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (product.type == ListingType.bundle &&
        product.bundleItems != null &&
        product.bundleItems!.isNotEmpty) {
      return Text(
        "${product.bundleItems!.join(' + ')} for ₱${product.price.toStringAsFixed(2)}",
        style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
      );
    }

    if (product.type == ListingType.promo && product.promoQuantity != null) {
      return Text(
        "${product.name} * ${product.promoQuantity} for ₱${product.price.toStringAsFixed(2)}",
        style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.sku.isNotEmpty)
          Text(
            "SKU: ${product.sku}",
            style: textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontSize: 10,
            ),
          ),
        Text(
          product.description,
          style: textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Widget _stockButton({required IconData icon, required VoidCallback onTap}) {
  //   return InkWell(
  //     onTap: onTap,
  //     borderRadius: BorderRadius.circular(50),
  //     child: Container(
  //       width: 27,
  //       height: 27,
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(50),
  //         border: Border.all(color: Colors.grey.shade300),
  //       ),
  //       child: Icon(icon, size: 13),
  //     ),
  //   );
  // }
}
