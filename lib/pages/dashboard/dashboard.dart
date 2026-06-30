import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:campusgo/pages/rewards/redemption_history.dart';
// import 'package:campusgo/providers/auth_provider.dart';
// import 'package:campusgo/models/enums.dart';
import 'home.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/navbar.dart';
import '../rewards/shops_dashboard.dart';
import '../../services/auth_service.dart';

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
  late int selectedIndex;
  final AuthService _authService = AuthService();
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // mark user online initially
    _authService.updateUserStatus(true);
    _startHeartbeat();

    if (widget.backToProcessing == true) {
      selectedIndex = 2;
    } else {
      selectedIndex = widget.openTab ?? 0;
    }
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authService.currentUser == null) return;

    if (state == AppLifecycleState.resumed) {
      _authService.updateUserStatus(true);
      _startHeartbeat();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _authService.updateUserStatus(false);
      _stopHeartbeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(accountType: widget.accountType),
      ShopsDashboardScreen(),
      HistoryScreen(
        accountType: widget.accountType,
        openTab: widget.backToProcessing == true ? 1 : 0,
      ),
    ];

    return Scaffold(
      extendBody: true,
      appBar: const TopBar(title: "campusgo", dashboard: true),
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
                  color: Colors.white,
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
                    setState(() {
                      selectedIndex = index;
                    });
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
