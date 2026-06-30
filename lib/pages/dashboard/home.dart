import 'package:flutter/material.dart';
import '../../pages/dashboard/organizer_dashboard.dart';
import 'user_dashboard.dart';
import '../../widgets/toggle_pages.dart';

class HomeDashboardScreen extends StatefulWidget {
  final String accountType;

  const HomeDashboardScreen({super.key, required this.accountType});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isOrganizer = widget.accountType == "Organizer";

    return isOrganizer
        ? TogglePagesButton(
            pages: [HomeScreen(isOrganizer: true), const OrganizerDashboard()],
            customTitles: ["Home", "Organizer"],
          )
        : const HomeScreen(isOrganizer: false);
  }
}
