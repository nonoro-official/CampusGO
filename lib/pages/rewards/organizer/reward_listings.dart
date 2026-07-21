import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/search.dart';
import '../../../widgets/filter.dart';
import '../../../widgets/top_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/reward_provider.dart';
import '../../../models/reward_item_model.dart';
import '../../../models/enums.dart';
import 'edit_reward_listings.dart';

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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF5F5F5),
      appBar: TopBar(
        title: 'Manage Listings',
        showBack: true,
        center: true,
        rightIcon: Icons.add,
        onRightPressed: () {
          if (user?.organizerId != null) {
            showListingModal(
              context: context,
              ref: ref,
              organizerId: user!.organizerId!,
            );
          }
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     if (user?.OrganizerId != null) {
      //       showListingModal(
      //         context: context,
      //         ref: ref,
      //         OrganizerId: user!.OrganizerId!,
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
                child: Text("Reward Listings", style: textTheme.titleLarge),
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
            if (user?.organizerId != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _CategoryFilter(
                  organizerId: user!.organizerId!,
                  selectedCategory: selectedCategory,
                  onChanged: (val) => setState(() => selectedCategory = val!),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: InventoryList(
                  organizerId: user.organizerId!,
                  searchQuery: searchQuery,
                  selectedType: selectedType,
                  selectedCategory: selectedCategory,
                ),
              ),
            ] else
              const Expanded(child: Center(child: Text('No Organizer found'))),
          ],
        ),
      ),
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
    final rewardsAsync = ref.watch(organizerRewardsProvider(organizerId));

    return rewardsAsync.when(
      data: (rewards) {
        final categories = rewards.expand((p) => p.categories).toSet().toList();
        categories.sort();
        final displayCategories = ["All Categories", ...categories];

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
  final String selectedType;
  final String selectedCategory;

  const InventoryList({
    super.key,
    required this.organizerId,
    required this.searchQuery,
    required this.selectedType,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(organizerRewardsProvider(organizerId));

    return rewardsAsync.when(
      data: (rewards) {
        final filteredRewards = rewards.where((reward) {
          final query = searchQuery.toLowerCase();
          final matchesSearch = reward.name.toLowerCase().contains(query) ||
              reward.description.toLowerCase().contains(query) ||
              (reward.sku.toLowerCase().contains(query)) ||
              (reward.categories.any((c) => c.toLowerCase().contains(query)));

          final matchesType =
              selectedType == "All Types" || reward.type.toName == selectedType;

          final matchesCategory = selectedCategory == "All Categories" ||
              reward.categories.contains(selectedCategory);

          return matchesSearch && matchesType && matchesCategory;
        }).toList();

        if (filteredRewards.isEmpty) {
          return const Center(child: Text("No rewards found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredRewards.length,
          itemBuilder: (context, index) {
            return ListingCard(
              reward: filteredRewards[index],
              allRewards: rewards,
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
  final RewardModel reward;
  final List<RewardModel> allRewards;

  const ListingCard({
    super.key,
    required this.reward,
    required this.allRewards,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    int stock = reward.calculateEffectiveStock(allRewards);

    // final isOutOfStock = stock <= 0;
    // final isLowStock = stock < 10 && stock > 0;

    // Color statusColor = !reward.isAvailable || isOutOfStock
    //     ? Colors.red
    //     : isLowStock
    //     ? Colors.orange
    //     : Colors.green;

    // String statusText = !reward.isAvailable
    //     ? "Unavailable"
    //     : (isOutOfStock
    //           ? "Out of Stock"
    //           : (isLowStock ? "Low Stock" : "In Stock"));

    // Color based on listing type
    Color typeColor;
    switch (reward.type) {
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
          organizerId: reward.organizerId,
          reward: reward,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
                      Text(reward.name, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      _buildPointsInfo(context),
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
                        reward.type.toName,
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
            if (reward.categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 4,
                  children: reward.categories
                      .map(
                        (cat) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHigh
                                    : Colors.grey.shade100,
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
                // if (reward.type == ListingType.regular || (reward.type == ListingType.discount && reward.linkedRewardId == null))
                //   Row(
                //     children: [
                //       _stockButton(
                //         icon: Icons.remove,
                //         onTap: () {
                //           if (reward.stock > 0) {
                //             rewardService.updateStock(
                //               rewardId: reward.id,
                //               newStock: reward.stock - 1,
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
                //           rewardService.updateStock(
                //             rewardId: reward.id,
                //             newStock: reward.stock + 1,
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
          'Are you sure you want to delete "${reward.name}"? This action cannot be undone.',
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
      await ref.read(rewardServiceProvider).deleteOrganizerReward(reward.id);
    }
  }

  Widget _buildPointsInfo(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    int? originalPoints = reward.originalPoints;

    // Automatically calculate original points for bundles/promos if missing or not reflecting base items
    if (originalPoints == null || originalPoints <= reward.points) {
      if (reward.type == ListingType.bundle && reward.bundleItems != null) {
        int total = 0;
        for (var itemName in reward.bundleItems!) {
          final item = allRewards.firstWhereOrNull(
            (p) =>
                p.name == itemName &&
                (p.type == ListingType.regular ||
                    (p.type == ListingType.discount &&
                        p.linkedRewardId == null)),
          );
          if (item != null) total += item.points;
        }
        if (total > reward.points) originalPoints = total;
      } else if (reward.type == ListingType.promo &&
          reward.promoQuantity != null) {
        final baseItem = allRewards.firstWhereOrNull(
          (p) =>
              (reward.linkedRewardId != null
                  ? p.id == reward.linkedRewardId
                  : p.name == reward.name) &&
              (p.type == ListingType.regular ||
                  (p.type == ListingType.discount && p.linkedRewardId == null)),
        );
        if (baseItem != null) {
          int total = baseItem.points * reward.promoQuantity!;
          if (total > reward.points) originalPoints = total;
        }
      }
    }

    bool hasDiscount = originalPoints != null && originalPoints > reward.points;

    if (hasDiscount) {
      double discountPercentage = reward.discountPercentage ??
          ((1 - (reward.points / originalPoints)) * 100);
      return Row(
        children: [
          Text(
            "${reward.points} pts",
            style: textTheme.bodySmall?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "$originalPoints pts",
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
      "${reward.points} pts",
      style: textTheme.bodySmall?.copyWith(
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildListingDetails(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (reward.type == ListingType.bundle &&
        reward.bundleItems != null &&
        reward.bundleItems!.isNotEmpty) {
      return Text(
        "${reward.bundleItems!.join(' + ')} for ${reward.points} pts",
        style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
      );
    }

    if (reward.type == ListingType.promo && reward.promoQuantity != null) {
      return Text(
        "${reward.name} * ${reward.promoQuantity} for ${reward.points} pts",
        style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reward.sku.isNotEmpty)
          Text(
            "SKU: ${reward.sku}",
            style: textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontSize: 10,
            ),
          ),
        Text(
          reward.description,
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
