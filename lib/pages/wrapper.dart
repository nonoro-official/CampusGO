import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import 'dashboard/dashboard.dart';
import '../pages/auth/login.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums.dart';

class Wrapper extends ConsumerWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. WATCH userDocProvider (this returns your custom UserModel)
    final userAsync = ref.watch(userDocProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  "Authentication Error",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    AuthService().signOut();
                    ref.invalidate(userDocProvider);
                  },
                  child: const Text("Back to Login"),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (user) {
        if (user == null) return const LoginScreen();

        // Init FCM once we know who the user is
        FCMService.init();
        // Return the dashboard directly to avoid the "navigation flicker".
        // This ensures the UI stays reactive to auth changes without
        // intermediate loading frames.
        return DashboardScreen(
          accountType: (user.role == Role.organizer || user.role == Role.coOrganizer)
              ? 'Organizer'
              : 'Customer',
        );
      },
    );
  }
}
