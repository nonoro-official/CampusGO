import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cart_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/organizer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/redemption_order_model.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final cartsAsync = ref.watch(myCartsProvider);

    return cartsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading cart: $e')),
      data: (carts) {
        if (carts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your cart is empty',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 10),
          itemCount: carts.length,
          itemBuilder: (context, index) {
            final cart = carts[index];
            return _CartCard(cart: cart);
          },
        );
      },
    );
  }
}

class _CartCard extends ConsumerStatefulWidget {
  final CartItemModel cart;
  const _CartCard({required this.cart});

  @override
  ConsumerState<_CartCard> createState() => _CartCardState();
}

class _CartCardState extends ConsumerState<_CartCard> {
  bool _isLocalLoading = false;

  Future<void> _handleCheckout(
    BuildContext context,
    CartItemModel enriched,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Text(
          'Place order for ${enriched.lineItems.length} item(s) '
          'totalling ${enriched.points} pts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLocalLoading = true);
    try {
      await ref.read(cartNotifierProvider.notifier).checkout(enriched);
      final state = ref.read(cartNotifierProvider);

      if (context.mounted) {
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(state.error.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order placed successfully!')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLocalLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final primaryColor = theme.primaryColor;
    final user = ref.watch(currentUserProvider);

    final enrichedAsync = ref.watch(enrichedCartProvider(widget.cart));

    return enrichedAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text('Error: $e'),
      ),
      data: (enriched) {
        if (enriched.lineItems.isEmpty) {
          return const SizedBox.shrink();
        }

        final total = enriched.points;
        final hasEnoughPoints = user != null && user.points >= total;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                children: [
                  Icon(Icons.storefront, size: 18, color: primaryColor),
                  const SizedBox(width: 6),
                  Consumer(
                    builder: (context, ref, child) {
                      final organizerAsync = ref.watch(
                        organizerProvider(enriched.organizerId),
                      );
                      return organizerAsync.when(
                        data: (b) => Text(
                          'Organizer: ${b?.organizerName ?? enriched.organizerId}',
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        loading: () => Text(
                          'Organizer: ...',
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        error: (_, __) => Text(
                          'Organizer: ${enriched.organizerId}',
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  Text(
                    '${enriched.points} pts',
                    style: textTheme.titleSmall?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (user != null && !hasEnoughPoints)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Insufficient points. You need ${total - user.points} more pts.',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ...enriched.lineItems.map((item) {
              return Dismissible(
                key: ValueKey('${enriched.id}_${item.rewardId}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                onDismissed: (_) {
                  ref.read(cartNotifierProvider.notifier).removeReward(
                        cartId: enriched.id,
                        rewardId: item.rewardId,
                        currentRewards: enriched.rewards,
                      );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.outlineVariant
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 55,
                        width: 55,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: item.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(Icons.shopping_bag, color: primaryColor),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              'Qty: ${item.quantity}',
                              style: textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${item.total} pts',
                              style: textTheme.titleSmall?.copyWith(
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          _QtyButton(
                            icon: Icons.add,
                            onTap: _isLocalLoading
                                ? () {}
                                : () async {
                                    setState(() => _isLocalLoading = true);
                                    try {
                                      await ref
                                          .read(cartNotifierProvider.notifier)
                                          .updateQuantity(
                                            cartId: enriched.id,
                                            rewardId: item.rewardId,
                                            newQuantity: item.quantity + 1,
                                            currentRewards: enriched.rewards,
                                          );

                                      final state =
                                          ref.read(cartNotifierProvider);
                                      if (state.hasError && context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              state.error.toString().replaceAll(
                                                  'Exception: ', ''),
                                            ),
                                            backgroundColor:
                                                Colors.orange.shade800,
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted)
                                        setState(() => _isLocalLoading = false);
                                    }
                                  },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${item.quantity}',
                              style: textTheme.titleSmall,
                            ),
                          ),
                          _QtyButton(
                            icon: Icons.remove,
                            onTap: _isLocalLoading
                                ? () {}
                                : () async {
                                    if (item.quantity > 1) {
                                      setState(() => _isLocalLoading = true);
                                      try {
                                        await ref
                                            .read(cartNotifierProvider.notifier)
                                            .updateQuantity(
                                              cartId: enriched.id,
                                              rewardId: item.rewardId,
                                              newQuantity: item.quantity - 1,
                                              currentRewards: enriched.rewards,
                                            );
                                      } finally {
                                        if (mounted)
                                          setState(
                                              () => _isLocalLoading = false);
                                      }
                                    } else {
                                      ref
                                          .read(cartNotifierProvider.notifier)
                                          .removeReward(
                                            cartId: enriched.id,
                                            rewardId: item.rewardId,
                                            currentRewards: enriched.rewards,
                                          );
                                    }
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isLocalLoading || !hasEnoughPoints)
                    ? null
                    : () => _handleCheckout(context, enriched),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLocalLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onPrimary
                              : Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart_checkout),
                          const SizedBox(width: 8),
                          Text(
                            'Place Order  •  $total pts',
                          ),
                        ],
                      ),
              ),
            ),
            const Divider(height: 30),
          ],
        );
      },
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.outline
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
