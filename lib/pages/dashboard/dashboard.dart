import 'package:campusgo/pages/rewards/qr_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:campusgo/pages/rewards/redemption_history.dart';
import 'home.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/navbar.dart';
import '../rewards/rewards_shops_screen.dart';
import '../map/campus_map_page.dart';
import '../map/organizer_map_page.dart';
import '../../services/auth_service.dart';
import '../../providers/navigation_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final String accountType;
  final int? openTab;
  final bool? backToProcessing;

  const DashboardScreen({
    super.key,
    required this.accountType,
    this.openTab,
    this.backToProcessing,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authService.updateUserStatus(true);
    _startHeartbeat();

    // Use addPostFrameCallback to set the initial index in the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.backToProcessing == true) {
        ref.read(dashboardTabIndexProvider.notifier).setIndex(4);
      } else if (widget.openTab != null) {
        ref.read(dashboardTabIndexProvider.notifier).setIndex(widget.openTab!);
      } else {
        ref.read(dashboardTabIndexProvider.notifier).setIndex(0);
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_authService.currentUser != null) {
        _authService.updateUserStatus(true);
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopHeartbeat();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authService.currentUser == null) return;
    if (state == AppLifecycleState.resumed) {
      _authService.updateUserStatus(true);
      _startHeartbeat();
    } else {
      _authService.updateUserStatus(false);
      _stopHeartbeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOrganizer = widget.accountType == 'Organizer';
    final selectedIndex = ref.watch(dashboardTabIndexProvider);

    final screens = [
      HomeDashboardScreen(accountType: widget.accountType),
      isOrganizer
          ? const AdminMapPage()
          : const UserMapPage(searchQuery: '', activeFilter: 'All'),
      const MockQRScannerPage(),
      const ShopsDashboardScreen(),
      HistoryScreen(
        accountType: widget.accountType,
        openTab: widget.backToProcessing == true ? 1 : 0,
      ),
    ];

    return Scaffold(
      extendBody: true,
      appBar: const TopBar(title: "CampusGO", dashboard: true),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(index: selectedIndex, children: screens),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.only(bottom: 20, top: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: NavBar(
                  selectedIndex: selectedIndex,
                  onTap: (index) {
                    ref
                        .read(dashboardTabIndexProvider.notifier)
                        .setIndex(index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
