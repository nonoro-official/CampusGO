import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/search.dart';
import '../../../widgets/top_bar.dart';
import '../../../widgets/filter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/organizer_provider.dart';
import '../../../models/reward_item_model.dart';
import '../../../models/enums.dart';
import 'reward_item_inventory.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String searchQuery = "";
  String selectedCategory = "All";

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);
    final OrganizerAsync = ref.watch(myOrganizerProvider);

    return OrganizerAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text("Error: $err"))),
      data: (Organizer) {
        if (Organizer == null) return const SizedBox.shrink();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: TopBar(
            title: Organizer.organizerName,
            showBack: true,
            center: true,
            rightIcon: Icons.add,
            onRightPressed: () => addItemInventory(context),
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text("Inventory", style: textTheme.titleLarge),
                const SizedBox(height: 10),
                if (user?.organizerId != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SearchBarWidget(
                            onSearch: (val) =>
                                setState(() => searchQuery = val),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _CategoryFilter(
                            organizerId: user!.organizerId!,
                            selectedCategory: selectedCategory,
                            onChanged: (val) =>
                                setState(() => selectedCategory = val!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: InventoryList(
                      organizerId: user.organizerId!,
                      searchQuery: searchQuery,
                      selectedCategory: selectedCategory,
                    ),
                  ),
                ] else
                  const Expanded(
                    child: Center(child: Text('No Organizer found')),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  final String organizerId;
  final String selectedCategory;
  final ValueChanged<String?> onChanged;

  const _CategoryFilter({
    required this.organizerId,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(organizerProductsProvider(organizerId));

    return productsAsync.when(
      data: (products) {
        // Only get categories from "base" products (Regular or unlinked Discount)
        final categories = products
            .where(
              (p) =>
                  p.type == ListingType.regular ||
                  (p.type == ListingType.discount && p.linkedProductId == null),
            )
            .expand((p) => p.categories)
            .toSet()
            .toList();
        categories.sort();
        final displayCategories = ["All", ...categories];

        return FilterWidget(
          options: displayCategories,
          selectedValue: selectedCategory,
          onChanged: onChanged,
        );
      },
      loading: () => const SizedBox(height: 45),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class InventoryList extends ConsumerWidget {
  final String organizerId;
  final String searchQuery;
  final String selectedCategory;

  const InventoryList({
    super.key,
    required this.organizerId,
    required this.searchQuery,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(organizerProductsProvider(organizerId));

    return productsAsync.when(
      data: (products) {
        final filtered = products
            .where((p) {
              // Base filter logic: Show Regular OR base Discount items (unlinked)
              return p.type == ListingType.regular ||
                  (p.type == ListingType.discount && p.linkedProductId == null);
            })
            .where((p) {
              // Search filter
              final query = searchQuery.toLowerCase();
              return p.name.toLowerCase().contains(query) ||
                  p.description.toLowerCase().contains(query) ||
                  p.categories.any((c) => c.toLowerCase().contains(query));
            })
            .where((p) {
              // Category filter
              return selectedCategory == "All" ||
                  p.categories.contains(selectedCategory);
            })
            .toList();

        if (filtered.isEmpty) {
          return const Center(child: Text("No products found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return ItemCard(item: filtered[index], allProducts: products);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class ItemCard extends ConsumerWidget {
  final ProductModel item;
  final List<ProductModel> allProducts;

  const ItemCard({super.key, required this.item, required this.allProducts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productService = ref.read(productServiceProvider);
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    int stock = item.calculateEffectiveStock(allProducts);

    final isOutOfStock = stock <= 0;
    final isLowStock = stock < 10 && stock > 0;

    Color statusColor = !item.isAvailable || isOutOfStock
        ? Colors.red
        : isLowStock
        ? Colors.orange
        : Colors.green;

    String statusText = !item.isAvailable
        ? "Unavailable"
        : (isOutOfStock
              ? "Out of Stock"
              : (isLowStock ? "Low Stock" : "In Stock"));

    final isDiscounted = item.type == ListingType.discount;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(item.name, style: textTheme.titleMedium),
                        if (isDiscounted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "SALE",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.categories.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: item.categories
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
                    const SizedBox(height: 2),
                    if (isDiscounted)
                      Row(
                        children: [
                          Text(
                            '${item.points.toStringAsFixed(2)} pts',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (item.discountPercentage != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '-${item.discountPercentage!.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      )
                    else
                      Text(
                        '${item.points.toStringAsFixed(2)} pts',
                        style: textTheme.bodySmall?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  editItemInventory(context, item);
                },
                icon: Icon(Icons.edit, color: primaryColor),
              ),
              IconButton(
                onPressed: () {
                  deleteItemInventory(context, item);
                },
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _stockButton(
                    icon: Icons.remove,
                    onTap: () {
                      if (item.stock > 0) {
                        productService.updateStock(
                          productId: item.id,
                          newStock: item.stock - 1,
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 14),
                  Text("$stock", style: textTheme.bodyLarge),
                  const SizedBox(width: 14),
                  _stockButton(
                    icon: Icons.add,
                    onTap: () {
                      productService.updateStock(
                        productId: item.id,
                        newStock: item.stock + 1,
                      );
                    },
                  ),
                ],
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stockButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 13),
      ),
    );
  }
}
