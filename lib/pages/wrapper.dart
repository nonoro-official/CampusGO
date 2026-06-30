import 'package:flutter/material.dart';
import '../services/fcm_service.dart';
import 'dashboard/dashboard.dart';
import '../pages/auth/login.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';

class Wrapper extends ConsumerWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. WATCH userDocProvider (this returns your custom UserModel)
    final userAsync = ref.watch(userDocProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => const LoginScreen(),
      data: (user) {
        if (user == null) return const LoginScreen();

        // Init FCM once we know who the user is
        FCMService.init();
        // Return the dashboard directly to avoid the "navigation flicker".
        // This ensures the UI stays reactive to auth changes without
        // intermediate loading frames.
        return DashboardScreen(
          accountType: (user.role == Role.vendor || user.role == Role.coVendor)
              ? 'Vendor'
              : 'Customer',
        );
      },
    );
  }
}
