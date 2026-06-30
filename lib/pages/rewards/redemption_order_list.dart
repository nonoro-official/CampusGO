import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/redemption_order_model.dart';
import '../../providers/order_provider.dart';
import 'redemption_summary.dart';
import '../../widgets/filter.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  final String filter; // "Processing" or "Completed"
  final String accountType;

  const OrdersScreen({
    super.key,
    required this.filter,
    required this.accountType,
  });

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String currentFilter = "All";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final primaryColor = theme.primaryColor;

    // Use the correct provider based on account type
    final ordersAsync = ref.watch(myOrdersProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading orders: $e')),
      data: (orders) {
        // Filter based on tab (Processing = active orders, Completed = done)
        final filtered = orders.where((order) {
          final status = order.orderStatus;

          // Tab filter
          bool matchesTab;
          if (widget.filter == "Completed") {
            matchesTab = 
            status == OrderStatus.completed ||
            status == OrderStatus.cancelled;
          } else {
            // "Processing" tab shows: toPayment (readyForPickUp), processing
            matchesTab =
                status == OrderStatus.readyForPickup ||
                status == OrderStatus.processing;
          }

          // Dropdown filter
          bool matchesDropdown =
              currentFilter == "All" || status.toName == currentFilter;

          return matchesTab && matchesDropdown;
        }).toList();

        return Column(
          children: [
            const SizedBox(height: 70), // Added spacing to clear toggle buttons
            if (widget.filter != "Completed")
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 5,
                  ),
                  child: FilterWidget(
                    options: const ["All", "To Payment", "Processing"],
                    selectedValue: currentFilter,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => currentFilter = val);
                      }
                    },
                  ),
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No orders yet',
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final order = filtered[index];
                        return _OrderCard(
                          order: order,
                          accountType: widget.accountType,
                          primaryColor: primaryColor,
                          textTheme: textTheme,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Order card ──────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final String accountType;
  final Color primaryColor;
  final TextTheme textTheme;

  const _OrderCard({
    required this.order,
    required this.accountType,
    required this.primaryColor,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final status = order.orderStatus;
    bool isPayment = status == OrderStatus.readyForPickup;

    final Color statusColor = switch (status) {
      OrderStatus.completed => Colors.green,
      OrderStatus.readyForPickup => Colors.blue,
      OrderStatus.processing => Colors.orange,
      OrderStatus.cancelled => Colors.redAccent,
      // OrderStatus.toPayment => Colors.redAccent,
    };

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OrderSummary(order: order, accountType: accountType),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
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
              child: Icon(Icons.shopping_bag, color: primaryColor),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${(order.orderNumber ?? order.id.substring(0, 6)).toUpperCase()}',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('Qty: ${order.totalQty}', style: textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    '₱${order.price.toStringAsFixed(2)}',
                    style: textTheme.titleSmall?.copyWith(color: primaryColor),
                  ),
                ],
              ),
                ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPayment ? "To Payment" : status.toName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
