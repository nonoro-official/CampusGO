import 'package:flutter/material.dart';
import '../../widgets/toggle_pages.dart';
import 'redemption_order_list.dart';
import 'redemption_cart.dart';

class HistoryScreen extends StatefulWidget {
  final String accountType;
  final int? openTab;

  const HistoryScreen({super.key, required this.accountType, this.openTab});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return TogglePagesButton(
      pages: [
        const CartScreen(),
        const OrdersScreen(filter: "Processing", accountType: "Customer"),
        const OrdersScreen(filter: "Completed", accountType: "Customer"),
      ],
      customTitles: ["Cart", "Processing", "Completed"],
      initialPage: widget.openTab,
    );
  }
}
