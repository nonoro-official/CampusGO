import 'package:flutter/material.dart';
import 'user_dashboard.dart';
// import '../widgets/toggle_pages.dart';

class ShopsDashboardScreen extends StatefulWidget {
  // final String accountType;

  // const ShopsDashboardScreen({super.key, required this.accountType});
  const ShopsDashboardScreen({super.key});

  @override
  State<ShopsDashboardScreen> createState() => _ShopsDashboardScreenState();
}

class _ShopsDashboardScreenState extends State<ShopsDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return CategoryGridView();
    // TogglePagesButton(
    //   pages: [CategoryGridView() /*, CategoryGridView()*/],
    //   customTitles: ["Shops"],
    // );
  }
}
