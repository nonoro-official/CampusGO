import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusgo/models/order_model.dart';
import 'package:campusgo/providers/order_provider.dart';
import 'package:campusgo/services/business_service.dart';
import 'package:campusgo/services/message_service.dart';
import '../../../widgets/top_bar.dart';
import '../../../widgets/modal.dart';
import '../chat_page.dart';

class OrderSummary extends ConsumerWidget {
  final OrderModel order;
  final String accountType; // 'Customer' or 'Vendor'

  const OrderSummary({
    super.key,
    required this.order,
    this.accountType = 'Vendor',
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
        
        // enriched.price is the total stored in the DB (includes the 10 pesos fee)
        final double total = enriched.price;
        const double serviceFee = 10.0;
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
                    'Total: ₱${total.toStringAsFixed(2)}',
                    style: textTheme.titleMedium?.copyWith(color: primaryColor),
                  ),
                ),

                /// BUYER VIEW (Regardless of user's role, if they are viewing through their History/Cart)
                if (accountType == "Customer") ...[
                  if (status == OrderStatus.processing)
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final business = await BusinessService().getBusiness(enriched.businessId);
                            if (business != null) {
                              await MessageService().initiateContact(business.ownerId);
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      receiverName: business.businessName,
                                      receiverID: business.ownerId,
                                      receiverImageUrl: business.imageUrl,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text("Contact Seller"),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                          onPressed: () =>
                              _cancelCustomerOrder(context, ref, enriched),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    )
                  else if (status == OrderStatus.completed)
                    ElevatedButton(
                      onPressed: () =>
                          _handleBuyAgain(context, ref, enriched.businessId),
                      child: const Text("Buy Again"),
                    )
                ]

                /// SELLER VIEW (Vendor viewing incoming orders from customers)
                else ...[
                  if (status == OrderStatus.processing ||
                      status == OrderStatus.readyForPickup)
                    Row(
                      children: [
                        if (status == OrderStatus.processing)
                        ElevatedButton(
                          onPressed: statusNotifier.isLoading 
                              ? null 
                              : () => _onVendorAction(context, ref, enriched, status, total),
                          child: const Text("Mark Ready"),
                        ),
                        if (status == OrderStatus.readyForPickup)
                          ElevatedButton(
                            onPressed: statusNotifier.isLoading 
                                ? null 
                                : () => _onVendorAction(context, ref, enriched, status, total),
                            child: const Text("Confirm Payment"),
                          ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                          onPressed: () =>
                              _cancelVendorOrder(context, ref, enriched, status),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    )
                  else if (status == OrderStatus.completed)
                    const Text(
                      "Completed",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    )
                ],
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
                              '₱${total.toStringAsFixed(2)}',
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

                // ─ Price breakdown ───────────────────────────────────
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
                        '₱${subtotal.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 10),
                      _buildRow(
                        context,
                        'Service Fee',
                        '₱${serviceFee.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 10),
                      _buildRow(context, 'Campus Pickup', 'Free'),
                      const Divider(height: 25),
                      _buildRow(
                        context,
                        'Total Payment',
                        '₱${total.toStringAsFixed(2)}',
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

  void _onVendorAction(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    OrderStatus status,
    double total,
  ) {
    if (status == OrderStatus.processing) {
      ModalContainer.popup(
        context: context,
        child: _ConfirmModal(
          title: 'Order Ready!',
          body:
              'This order will be marked as ready for pickup and the customer will be notified.',
          confirmLabel: 'Mark Ready',
          onConfirm: () async {
            Navigator.pop(context);
            await ref
                .read(orderStatusNotifierProvider.notifier)
                .updateStatus(order.id, OrderStatus.readyForPickup);
            if (context.mounted) Navigator.pop(context);
          },
          onCancel: () => Navigator.pop(context),
        ),
      );
    } 
    else if (status == OrderStatus.readyForPickup) {
      ModalContainer.popup(
        context: context,
        child: _ConfirmModal(
          title: 'Confirm Payment',
          body:
              'Confirm that the customer has paid ₱${total.toStringAsFixed(2)}?',
          confirmLabel: 'Confirm Payment',
          onConfirm: () async {
            Navigator.pop(context);
            await ref
                .read(orderStatusNotifierProvider.notifier)
                .updateStatus(order.id, OrderStatus.completed);
            if (context.mounted) Navigator.pop(context);
          },
          onCancel: () => Navigator.pop(context),
        ),
      );
    }
  }

  Future<void> _handleBuyAgain(
    BuildContext context,
    WidgetRef ref,
    String businessId,
  ) async {
    try {
      final businessService = BusinessService();
      final business = await businessService.getBusiness(businessId);

      if (business != null && context.mounted) {
        Navigator.pushNamed(context, '/vendor-profile', arguments: business);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor no longer available')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _cancelVendorOrder(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    OrderStatus status,
  ) {
    ModalContainer.popup(
      context: context,
      child: _ConfirmModal(
        title: 'Cancel Order',
        body:
            'Are you sure you want to cancel this order? This cannot be undone.',
        confirmLabel: 'Cancel Order',
        onConfirm: () async {
          Navigator.pop(context);
          await ref
              .read(orderStatusNotifierProvider.notifier)
              .updateStatus(order.id, OrderStatus.cancelled);
          if (context.mounted) {
             Navigator.pop(context);
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Order cancelled")),
             );
          }
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _cancelCustomerOrder(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    ModalContainer.popup(
      context: context,
      child: _ConfirmModal(
        title: 'Cancel Order',
        body: 'Do you want to cancel this order?',
        confirmLabel: 'Yes, Cancel',
        onConfirm: () async {
          Navigator.pop(context);
          await ref
              .read(orderStatusNotifierProvider.notifier)
              .updateStatus(order.id, OrderStatus.cancelled);
          if (context.mounted) Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
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

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final String accountType;

  const _StatusBadge({required this.status, required this.accountType});

  @override
  Widget build(BuildContext context) {
    String label = status == OrderStatus.readyForPickup
        ? "To Payment"
        : status.toName;

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
                  '₱${item.total.toStringAsFixed(2)}',
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
