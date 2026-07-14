import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusgo/models/redemption_order_model.dart';
import 'package:campusgo/providers/order_provider.dart';
import 'redemption_order_details.dart';
import '../../../widgets/top_bar.dart';
import '../../../widgets/search.dart';
import '../../../widgets/filter.dart';

class OrderList extends ConsumerStatefulWidget {
  const OrderList({super.key});

  @override
  ConsumerState<OrderList> createState() => _OrderListState();
}

class _OrderListState extends ConsumerState<OrderList> {
  String currentFilter = "All";
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final primaryColor = theme.primaryColor;

    final ordersAsync = ref.watch(organizerOrdersProvider);

    return Scaffold(
      appBar: TopBar(title: 'Incoming Orders', showBack: true),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SearchBarWidget(
                      onSearch: (val) => setState(() => searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilterWidget(
                      options: const [
                        "All",
                        "Processing",
                        "Ready for Pickup",
                        "Completed",
                        "Cancelled",
                      ],
                      selectedValue: currentFilter,
                      onChanged: (val) => setState(() => currentFilter = val!),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Error loading orders: $e')),
                data: (orders) {
                  final filtered = orders.where((order) {
                    final status = order.orderStatus;

                    bool matchesFilter = false;
                    if (currentFilter == "All") {
                      matchesFilter = true;
                    } else if (currentFilter == "Completed") {
                      // Include both Completed and Cancelled in the "Completed" section as requested
                      matchesFilter = status == OrderStatus.completed ||
                          status == OrderStatus.cancelled;
                    } else {
                      matchesFilter = status.toName == currentFilter;
                    }

                    final matchesSearch = order.id.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        );

                    return matchesFilter && matchesSearch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        currentFilter == "Completed"
                            ? 'No completed or cancelled orders yet.'
                            : 'No orders found.',
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      final status = order.orderStatus;

                      final statusColor = switch (status) {
                        OrderStatus.completed => Colors.green,
                        OrderStatus.readyForPickup => Colors.blue,
                        OrderStatus.cancelled => Colors.redAccent,
                        OrderStatus.processing => Colors.orange,
                      };

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetails(order: order),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant
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
                                child: Icon(
                                  Icons.shopping_bag,
                                  color: primaryColor,
                                ),
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
                                    Text(
                                      'Qty: ${order.totalQty}',
                                      style: textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${order.points} pts',
                                      style: textTheme.titleSmall?.copyWith(
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status.toName,
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
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
