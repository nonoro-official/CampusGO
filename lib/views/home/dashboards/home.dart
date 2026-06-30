import 'package:flutter/material.dart';
import 'business_dashboard.dart';
import 'user_dashboard.dart';
import '../../../widgets/toggle_pages.dart';

class HomeDashboardScreen extends StatefulWidget {
  final String accountType;

  const HomeDashboardScreen({super.key, required this.accountType});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isVendor = widget.accountType == "Vendor";

    return isVendor
        ? TogglePagesButton(
            pages: [HomeScreen(isVendor: true), const BusinessDashboard()],
            customTitles: ["Home", "Business"],
          )
        : const HomeScreen(isVendor: false);
  }
}
