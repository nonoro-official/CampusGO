import 'package:flutter/material.dart';
import 'user_map_page.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';

class UserDashboardPage extends StatelessWidget {
  const UserDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const UserMapPage(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.logout),
        onPressed: () async {

          bool confirm = await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Logout"),
              content: const Text("Are you sure?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Logout")),
              ],
            ),
          );

          if (confirm == true) {
            await AuthService().logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
            );
          }
        },
      ),
    );
  }
}