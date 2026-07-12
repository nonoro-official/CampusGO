import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusgo/widgets/top_bar.dart';
import '../../models/reward_item_model.dart';
import '../../models/enums.dart';
import '../../providers/cart_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/redemption_order_model.dart';

class RewardDetailScreen extends ConsumerStatefulWidget {
  final dynamic reward;

  const RewardDetailScreen({super.key, required this.reward});

  @override
  ConsumerState<RewardDetailScreen> createState() =>
      _RewardDetailScreenState();
}

class _RewardDetailScreenState extends ConsumerState<RewardDetailScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final initialReward = widget.reward as RewardModel;
    
    // Watch the reward stream to get real-time stock updates
    final rewardsAsync = ref.watch(organizerRewardsProvider(initialReward.organizerId));
    
    return rewardsAsync.when(
      loading: () => _buildScaffold(context, initialReward),
      error: (e, _) => _buildScaffold(context, initialReward),
      data: (rewards) {
        final reward = rewards.firstWhere(
          (p) => p.id == initialReward.id,
          orElse: () => initialReward,
        );
        
        // Calculate effective stock if it's a promo, discount, or bundle
        final effectiveStock = reward.calculateEffectiveStock(rewards);
        
        // Adjust quantity if it exceeds current stock
        if (quantity > effectiveStock && effectiveStock > 0) {
          quantity = effectiveStock;
        } else if (effectiveStock == 0) {
          quantity = 0;
        }

        return _buildScaffold(context, reward, effectiveStock: effectiveStock);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, RewardModel reward, {int? effectiveStock}) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    final user = ref.watch(currentUserProvider);
    
    final displayStock = effectiveStock ?? reward.stock;
    final isOutOfStock = displayStock <= 0;
    final isLowStock = displayStock > 0 && displayStock <= 9;
    
    final totalPoints = (reward.points * quantity) + kServiceFeePoints;
    final hasEnoughPoints = user != null && user.points >= totalPoints;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: TopBar(title: "Reward", dark: true, showBack: true),
      body: Column(
        children: [
          /// PRODUCT IMAGE
          Stack(
            children: [
              ColorFiltered(
                colorFilter: isOutOfStock
                    ? const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0, 0, 0, 1, 0,
                      ])
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
                child: Container(
                  height: 260,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: reward.imageUrl != null
                      ? Image.network(reward.imageUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              ),
              if (isOutOfStock)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: Text(
                        "UNAVAILABLE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// NAME & STOCK STATUS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(reward.name, style: textTheme.titleLarge),
                        ),
                        if (isOutOfStock)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Out of Stock",
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isLowStock
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isLowStock
                                  ? "Only $displayStock left!"
                                  : "$displayStock in stock",
                              style: TextStyle(
                                color: isLowStock
                                    ? Colors.orange.shade900
                                    : Colors.green.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    /// PRICE
                    Row(
                      children: [
                        Text(
                          "${reward.points} pts",
                          style: textTheme.titleMedium?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (reward.originalPoints != null && reward.originalPoints! > reward.points) ...[
                          const SizedBox(width: 10),
                          Text(
                            "${reward.originalPoints} pts",
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (reward.discountPercentage != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "-${reward.discountPercentage!.toStringAsFixed(0)}%",
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),

                    if (user != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Your Points: ${user.points} pts",
                        style: textTheme.bodySmall?.copyWith(
                          color: hasEnoughPoints ? Colors.green : Colors.red,
                        ),
                      ),
                      if (!hasEnoughPoints)
                        Text(
                          "Need ${totalPoints - user.points} more pts (+$kServiceFeePoints pts fee)",
                          style: textTheme.labelSmall?.copyWith(color: Colors.red),
                        ),
                    ],

                    if (reward.categories.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: reward.categories.map((cat) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cat,
                            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                          ),
                        )).toList(),
                      ),
                    ],

                    const SizedBox(height: 20),

                    /// DESCRIPTION
                    Text("Description", style: textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Text(
                      reward.description.isNotEmpty
                          ? reward.description
                          : "No description available.",
                      style: textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 20),

                    /// ADDITIONAL INFO
                    if (reward.sku.isNotEmpty || reward.supplier.isNotEmpty) ...[
                      Text("Reward Details", style: textTheme.titleSmall),
                      const SizedBox(height: 10),
                      if (reward.sku.isNotEmpty)
                        _detailRow("SKU", reward.sku),
                      if (reward.supplier.isNotEmpty)
                        _detailRow("Supplier", reward.supplier),
                      const SizedBox(height: 20),
                    ],

                    /// QUANTITY SELECTOR
                    if (!isOutOfStock)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Quantity", style: textTheme.titleMedium),
                              Text(
                                "Max: $displayStock",
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _qtyButton(Icons.remove, () {
                                if (quantity > 1) {
                                  setState(() => quantity--);
                                }
                              }),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  "$quantity",
                                  style: textTheme.bodyLarge,
                                ),
                              ),
                              _qtyButton(Icons.add, () {
                                if (quantity < displayStock) {
                                  setState(() => quantity++);
                                }
                              }),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() => quantity = displayStock);
                                },
                                child: const Text("MAX"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),

          /// BUY BUTTONS
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isOutOfStock
                          ? null
                          : () async {
                              await ref
                                  .read(cartNotifierProvider.notifier)
                                  .addToCart(
                                    organizerId: reward.organizerId,
                                    reward: reward,
                                    quantity: quantity,
                                  );

                              if (context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${reward.name} x$quantity added to cart!',
                                    ),
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOutOfStock
                            ? Colors.grey
                            : primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Add to Cart",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (isOutOfStock || !hasEnoughPoints)
                          ? null
                          : () async {
                              // Show confirmation dialog
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Buy Now'),
                                  content: Text(
                                    'Place order for ${reward.name} x$quantity '
                                    'totalling $totalPoints pts (includes $kServiceFeePoints pts fee)?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('Confirm'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed != true) return;
                              
                              try {
                                await ref.read(cartNotifierProvider.notifier).buyNow(
                                  organizerId: reward.organizerId,
                                  reward: reward,
                                  quantity: quantity,
                                );
                                
                                if (context.mounted) {
                                  final user = ref.read(currentUserProvider);
                                  final route = user?.role != Role.customer ? '/Organizer-dashboard' : '/dashboard';
                                  
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    route,
                                    (route) => false,
                                    arguments: {'backToProcessing': true},
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOutOfStock
                            ? Colors.grey
                            : Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Buy Now",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
