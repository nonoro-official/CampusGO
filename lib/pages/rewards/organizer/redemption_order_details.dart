import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusgo/models/redemption_order_model.dart';
import 'package:campusgo/providers/order_provider.dart';
import '../../../widgets/top_bar.dart';
import '../../../widgets/modal.dart';

class OrderDetails extends ConsumerWidget {
  final OrderModel order;
  final String accountType; // 'Customer' or 'Organizer'

  const OrderDetails({
    super.key,
    required this.order,
    this.accountType = 'Organizer',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final primaryColor = theme.primaryColor;

    final enrichedAsync = ref.watch(enrichedOrderProvider(order));
    final statusNotifier = ref.watch(orderStatusNotifierProvider);

    return enrichedAsync.when(
      loading: () => Scaffold(
        appBar: TopBar(title: 'Order Summary', showBack: true, dark: true),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: TopBar(title: 'Order Summary', showBack: true, dark: true),
        body: Center(child: Text('Error: $e')),
      ),
      data: (enriched) {
        final List<OrderItemModel> items = enriched.items;
        final OrderStatus status = enriched.orderStatus;
        final bool isProcessing = status == OrderStatus.processing;
        final bool isReady = status == OrderStatus.readyForPickup;

        // Grand Total from DB
        final double total = enriched.points;
        const double serviceFee = 10.0;
        // Subtotal is (Grand Total - Fee)
        final double subtotal = (total - serviceFee).clamp(0, double.infinity);
        final int qty = enriched.totalQty;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),

          appBar: TopBar(title: 'Order Summary', showBack: true, dark: true),

          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total: ${total.toStringAsFixed(2)} pts',
                    style: textTheme.titleMedium?.copyWith(color: primaryColor),
                  ),
                ),
                // ─── Organizer view ───────────────────────────────────
                if (accountType == 'Organizer' && status != OrderStatus.completed)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: statusNotifier.isLoading
                        ? null
                        : () => _onOrganizerAction(
                            context,
                            ref,
                            enriched,
                            isProcessing,
                            isReady,
                            total,
                          ),
                    child: statusNotifier.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isProcessing
                                ? 'Mark Ready'
                                : isReady
                                ? 'Complete Order'
                                : 'Confirm',
                          ),
                  ),
              ],
            ),
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ─ Header card ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.shopping_bag,
                          size: 30,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${(enriched.orderNumber ?? enriched.id.substring(0, 6)).toUpperCase()}',
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${total.toStringAsFixed(2)} pts',
                              style: textTheme.titleSmall?.copyWith(
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Quantity: $qty', style: textTheme.bodySmall),
                            const SizedBox(height: 4),
                            _StatusBadge(
                              status: status,
                              accountType: accountType,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─ Line items ────────────────────────────────────────
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) =>
                      OrderItems(item: items[index]),
                ),

                const SizedBox(height: 10),

                // ─ Points breakdown ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildRow(
                        context,
                        'Subtotal',
                        '${subtotal.toStringAsFixed(2)} pts',
                      ),
                      const SizedBox(height: 10),
                      _buildRow(
                        context,
                        'Service Fee',
                        '${serviceFee.toStringAsFixed(2)} pts',
                      ),
                      const SizedBox(height: 10),
                      _buildRow(context, 'Campus Pickup', 'Free'),
                      const Divider(height: 25),
                      _buildRow(
                        context,
                        'Total Payment',
                        '${total.toStringAsFixed(2)} pts',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─ Payment method ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: primaryColor),
                      const SizedBox(width: 10),
                      Text('Cash on Pickup', style: textTheme.titleSmall),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Organizer action button handler ─────────────────────────────────────────

  void _onOrganizerAction(
    BuildContext context,
    WidgetRef ref,
    OrderModel enriched,
    bool isProcessing,
    bool isReady,
    double total,
  ) {
    if (isProcessing) {
      ModalContainer.popup(
        context: context,
        child: _ConfirmModal(
          title: 'Order Ready!',
          body:
              'The order is now ready for pickup. We will notify the customer.',
          confirmLabel: 'Mark Ready',
          onConfirm: () async {
            Navigator.pop(context); // close modal
            await ref
                .read(orderStatusNotifierProvider.notifier)
                .updateStatus(enriched.id, OrderStatus.readyForPickup);
            if (context.mounted) {
              Navigator.pop(context); // back to order list
            }
          },
          onCancel: () => Navigator.pop(context),
        ),
      );
    } else if (isReady) {
      ModalContainer.popup(
        context: context,
        child: _ConfirmModal(
          title: 'Complete Order',
          body:
              'Confirm that the customer has paid ${total.toStringAsFixed(2)} pts and picked up the items?',
          confirmLabel: 'Complete Order',
          onConfirm: () async {
            Navigator.pop(context); // close modal
            await ref
                .read(orderStatusNotifierProvider.notifier)
                .updateStatus(enriched.id, OrderStatus.completed);
            if (context.mounted) {
              Navigator.pop(context); // back to order list
            }
          },
          onCancel: () => Navigator.pop(context),
        ),
      );
    }
  }

  Widget _buildRow(
    BuildContext context,
    String title,
    String value, {
    bool isTotal = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: isTotal ? textTheme.titleSmall : textTheme.bodyMedium,
        ),
        Text(
          value,
          style: (isTotal ? textTheme.titleSmall : textTheme.bodyMedium)
              ?.copyWith(
                fontWeight: FontWeight.bold,
                color: isTotal ? primaryColor : Colors.black87,
              ),
        ),
      ],
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final String accountType;

  const _StatusBadge({required this.status, required this.accountType});

  @override
  Widget build(BuildContext context) {
    String label = status.toName;

    final color = switch (status) {
      OrderStatus.completed => Colors.green,
      OrderStatus.readyForPickup => Colors.blue,
      OrderStatus.processing => Colors.orange,
      OrderStatus.cancelled => Colors.redAccent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ─── Reusable confirm modal ───────────────────────────────────────────────────

class _ConfirmModal extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ConfirmModal({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 40),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: primaryColor,
                  fontSize: 20,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: onCancel,
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 15),
        Text(body, style: textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: onConfirm,
            child: Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}

// ─── Order item card ──────────────────────────────────────────────────────────

class OrderItems extends StatelessWidget {
  final OrderItemModel item;

  const OrderItems({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('Qty: ${item.quantity}', style: textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  '${item.total.toStringAsFixed(2)} pts',
                  style: textTheme.titleSmall?.copyWith(color: primaryColor),
                ),
              ],
            ),
          ),
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.shopping_bag, size: 16, color: primaryColor),
          ),
        ],
      ),
    );
  }
}
