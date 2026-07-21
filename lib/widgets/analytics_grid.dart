import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusgo/models/redemption_order_model.dart';
import 'package:campusgo/providers/order_provider.dart';
import 'package:campusgo/providers/reward_provider.dart';

class AnalyticsGrid extends ConsumerWidget {
  final String organizerId;

  const AnalyticsGrid({super.key, required this.organizerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = theme.colorScheme;
    final primaryColor = colors.primary;

    final ordersAsync = ref.watch(organizerOrdersProvider);
    final rewardsAsync = ref.watch(organizerRewardsProvider(organizerId));

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

        final Map<String, int> rewardSales = {};

        for (final order in completedOrders) {
          order.orders.forEach((rewardId, qty) {
            rewardSales.update(
              rewardId,
              (value) => value + qty,
              ifAbsent: () => qty,
            );
          });
        }

        String? mostPopularId;
        String? leastPopularId;

        if (rewardSales.isNotEmpty) {
          final most = rewardSales.entries.reduce(
            (a, b) => a.value > b.value ? a : b,
          );

          mostPopularId = most.key;
        }

        return rewardsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading rewards')),
          data: (rewards) {
            final activeListings = rewards.where((reward) {
              final stock = reward.calculateEffectiveStock(rewards);
              return stock > 0;
            }).length;

            final unsoldRewards =
                rewards.where((p) => !rewardSales.containsKey(p.id)).toList();

            if (unsoldRewards.length == 1) {
              leastPopularId = unsoldRewards.first.id;
            } else if (unsoldRewards.isEmpty && rewardSales.isNotEmpty) {
              final least = rewardSales.entries.reduce(
                (a, b) => a.value < b.value ? a : b,
              );
              leastPopularId = least.key;
            } else {
              leastPopularId = null;
            }

            String mostPopularName =
                mostPopularId == null ? "No data" : "Unknown Reward";

            String leastPopularName =
                leastPopularId == null ? "No data" : "Unknown Reward";

            if (mostPopularId != null) {
              final match =
                  rewards.where((p) => p.id == mostPopularId).toList();
              if (match.isNotEmpty) {
                mostPopularName = match.first.name;
              }
            }

            if (leastPopularId != null) {
              final match =
                  rewards.where((p) => p.id == leastPopularId).toList();
              if (match.isNotEmpty) {
                leastPopularName = match.first.name;
              }
            }

            final analytics = [
              {
                'label': 'Pending Orders',
                'value': pendingOrders.length.toString(),
                'icon': Icons.shopping_cart,
                'isReward': false,
              },
              {
                'label': 'Active Listings',
                'value': activeListings.toString(),
                'icon': Icons.inventory_2_outlined,
                'isReward': false,
              },
              {
                'label': 'Most Popular',
                'value': mostPopularName,
                'count':
                    mostPopularId != null ? rewardSales[mostPopularId] ?? 0 : 0,
                'isReward': true,
              },
              {
                'label': 'Least Popular',
                'value': leastPopularName,
                'count': leastPopularId != null
                    ? rewardSales[leastPopularId] ?? 0
                    : 0,
                'isReward': true,
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
                final bool isReward = item['isReward'] as bool;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? colors.outlineVariant
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isReward) ...[
                        Text(
                          '${item['count']} Sold',
                          style: textTheme.bodyMedium?.copyWith(
                            color: primaryColor,
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
