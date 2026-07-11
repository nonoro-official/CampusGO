import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusgo/models/redemption_order_model.dart';
import 'package:campusgo/providers/order_provider.dart';
import 'package:campusgo/providers/product_provider.dart';

class AnalyticsGrid extends ConsumerWidget {
  final String organizerId;

  const AnalyticsGrid({super.key, required this.organizerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final primaryColor = theme.primaryColor;

    final ordersAsync = ref.watch(OrganizerOrdersProvider);
    final productsAsync = ref.watch(organizerProductsProvider(organizerId));

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading orders')),
      data: (orders) {
        final today = DateTime.now();

        final todayOrders = orders.where((order) {
          final date = order.timestamp.toLocal();
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          // date.day == 19; // test to show specific day analytics
        }).toList();

        final completedOrders = todayOrders
            .where((o) => o.orderStatus == OrderStatus.completed)
            .toList();

        final pendingOrders = todayOrders.where(
          (o) =>
              o.orderStatus == OrderStatus.processing ||
              o.orderStatus == OrderStatus.readyForPickup,
        );

        final revenue = completedOrders.fold<double>(
          0.0,
          (sum, o) => sum + o.points,
        );

        final Map<String, int> productSales = {};

        for (final order in completedOrders) {
          order.orders.forEach((productId, qty) {
            productSales.update(
              productId,
              (value) => value + qty,
              ifAbsent: () => qty,
            );
          });
        }

        String? mostPopularId;
        String? leastPopularId;

        if (productSales.isNotEmpty) {
          final most = productSales.entries.reduce(
            (a, b) => a.value > b.value ? a : b,
          );

          mostPopularId = most.key;
        }

        return productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading products')),
          data: (products) {
            final activeListings = products.where((product) {
              final stock = product.calculateEffectiveStock(products);
              return stock > 0;
            }).length;

            final unsoldProducts = products
                .where((p) => !productSales.containsKey(p.id))
                .toList();

            if (unsoldProducts.length == 1) {
              leastPopularId = unsoldProducts.first.id;
            } else if (unsoldProducts.isEmpty && productSales.isNotEmpty) {
              final least = productSales.entries.reduce(
                (a, b) => a.value < b.value ? a : b,
              );
              leastPopularId = least.key;
            } else {
              leastPopularId = null;
            }

            String mostPopularName = mostPopularId == null
                ? "No data"
                : "Unknown Product";

            String leastPopularName = leastPopularId == null
                ? "No data"
                : "Unknown Product";

            if (mostPopularId != null) {
              final match = products
                  .where((p) => p.id == mostPopularId)
                  .toList();
              if (match.isNotEmpty) {
                mostPopularName = match.first.name;
              }
            }

            if (leastPopularId != null) {
              final match = products
                  .where((p) => p.id == leastPopularId)
                  .toList();
              if (match.isNotEmpty) {
                leastPopularName = match.first.name;
              }
            }

            final analytics = [
              {
                'label': 'Revenue',
                'value': '${revenue.toStringAsFixed(2)} pts',
                'icon': Icons.attach_money,
                'isProduct': false,
              },
              {
                'label': 'Total Sales',
                'value': completedOrders.length.toString(),
                'icon': Icons.trending_up,
                'isProduct': false,
              },
              {
                'label': 'Pending Orders',
                'value': pendingOrders.length.toString(),
                'icon': Icons.shopping_cart,
                'isProduct': false,
              },
              {
                'label': 'Active Listings',
                'value': activeListings.toString(),
                'icon': Icons.inventory_2_outlined,
                'isProduct': false,
              },
              {
                'label': 'Most Popular',
                'value': mostPopularName,
                'count': mostPopularId != null
                    ? productSales[mostPopularId] ?? 0
                    : 0,
                'isProduct': true,
              },
              {
                'label': 'Least Popular',
                'value': leastPopularName,
                'count': leastPopularId != null
                    ? productSales[leastPopularId] ?? 0
                    : 0,
                'isProduct': true,
              },
            ];

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: analytics.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) {
                final item = analytics[index];
                final bool isProduct = item['isProduct'] as bool;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isProduct) ...[
                        Text(
                          '${item['count']} Sold',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          item['icon'] as IconData,
                          color: primaryColor,
                          size: 22,
                        ),
                      ],
                      const Spacer(),
                      Text(
                        item['value'] as String,
                        style: textTheme.titleLarge?.copyWith(fontSize: 20),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(item['label'] as String, style: textTheme.bodySmall),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
