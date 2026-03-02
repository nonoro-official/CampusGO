import 'package:flutter/material.dart';
import 'edit_restaurant_tab.dart';
import 'history_tab.dart';
import 'vouchers_tab.dart';
import 'menu_tab.dart';
import 'orders_tab.dart';
import 'reviews_tab.dart'; // Import the new ReviewsTab

class RestaurantDetailDashboard extends StatefulWidget {
  final String restaurantId;
  final Map<String, dynamic> restaurantData;

  const RestaurantDetailDashboard({
    super.key,
    required this.restaurantId,
    required this.restaurantData
  });

  @override
  State<RestaurantDetailDashboard> createState() => _RestaurantDetailDashboardState();
}

class _RestaurantDetailDashboardState extends State<RestaurantDetailDashboard> {
  int _selectedTabIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    // Logic: Every tab must have a unique index (0 to 5)
    _tabs = [
      EditRestaurantTab(restaurantId: widget.restaurantId, data: widget.restaurantData), // 0
      MenuTab(restaurantId: widget.restaurantId),                                      // 1
      HistoryTab(restaurantId: widget.restaurantId),                                   // 2
      VouchersTab(restaurantId: widget.restaurantId),                                  // 3
      OrdersTab(restaurantId: widget.restaurantId),                                    // 4
      ReviewsTab(restaurantId: widget.restaurantId),                                   // 5
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantData['name']),
        backgroundColor: const Color(0xFFE46A3E),
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFFE46A3E)),
              child: Center(
                child: Text(
                  "Manage\n${widget.restaurantData['name']}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit Details"),
              selected: _selectedTabIndex == 0,
              onTap: () { setState(() => _selectedTabIndex = 0); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text("Edit Menu"),
              selected: _selectedTabIndex == 1,
              onTap: () { setState(() => _selectedTabIndex = 1); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("History Logs"),
              selected: _selectedTabIndex == 2,
              onTap: () { setState(() => _selectedTabIndex = 2); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.confirmation_number),
              title: const Text("Vouchers"),
              selected: _selectedTabIndex == 3,
              onTap: () { setState(() => _selectedTabIndex = 3); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long), // Using receipt icon for Orders
              title: const Text("Live Orders"),
              selected: _selectedTabIndex == 4,
              onTap: () { setState(() => _selectedTabIndex = 4); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.star_rate),
              title: const Text("Customer Reviews"),
              selected: _selectedTabIndex == 5,
              onTap: () { setState(() => _selectedTabIndex = 5); Navigator.pop(context); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const Text("Back to All Restaurants"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _tabs[_selectedTabIndex],
    );
  }
}