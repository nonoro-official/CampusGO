import 'package:flutter/material.dart';
import 'edit_restaurant_tab.dart';
import 'history_tab.dart';
import 'vouchers_tab.dart';

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

  // We pass the ID to each tab so they know which data to pull/save
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      EditRestaurantTab(restaurantId: widget.restaurantId, data: widget.restaurantData),
      HistoryTab(restaurantId: widget.restaurantId),
      VouchersTab(restaurantId: widget.restaurantId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantData['name']),
        backgroundColor: const Color(0xFFE46A3E),
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
              onTap: () { setState(() => _selectedTabIndex = 0); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("History Logs"),
              onTap: () { setState(() => _selectedTabIndex = 1); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.confirmation_number),
              title: const Text("Vouchers"),
              onTap: () { setState(() => _selectedTabIndex = 2); Navigator.pop(context); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const Text("Back to All Restaurants"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: _tabs[_selectedTabIndex],
    );
  }
}