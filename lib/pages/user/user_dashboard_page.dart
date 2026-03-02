import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_map_page.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';

import 'personal_details_page.dart';
import 'order_history_page.dart';
import 'saved_places_page.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String searchQuery = "";
  String activeFilter = "All";

  final List<String> quickFilters = ["All", "Filipino", "Fast Food", "Cafe", "Budget", "Free WiFi"];

  void logout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Logout", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false
      );
    }
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap ?? () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$title coming soon!")));
      },
    );
  }

  Widget _buildDrawer(String email) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          // NEW: StreamBuilder listens to the database live!
          StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                // Default fallback is still the first half of the email
                String displayName = email.split('@')[0].toUpperCase();

                // If they saved a real name in the database, use that instead!
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null && data.containsKey('name') && data['name'].toString().trim().isNotEmpty) {
                    displayName = data['name'].toString().toUpperCase();
                  }
                }

                return UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFFE46A3E)),
                  accountName: Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  accountEmail: Text(email, style: const TextStyle(color: Colors.white70)),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFFE46A3E), size: 40),
                  ),
                );
              }
          ),
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.white),
              title: const Text("Foodika PRO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Premium coming soon!")));
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerTile(Icons.person_outline, "Personal Details", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalDetailsPage()));
                }),
                _drawerTile(Icons.history, "Order History", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryPage()));
                }),
                _drawerTile(Icons.favorite_border, "Saved Places", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlacesPage()));
                }),
                const Divider(),
                _drawerTile(Icons.settings_outlined, "Settings", null),
                _drawerTile(Icons.help_outline, "Help & Support", null),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              onPressed: logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Log Out"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String userEmail = user?.email ?? "User"; // We only need the email now

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(userEmail), // Only pass the email here
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          UserMapPage(searchQuery: searchQuery, activeFilter: activeFilter),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search for food...",
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      suffixIcon: const Icon(Icons.search, color: Color(0xFFE46A3E)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: quickFilters.length,
                    itemBuilder: (context, index) {
                      String filter = quickFilters[index];
                      bool isSelected = activeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) => setState(() => activeFilter = filter),
                          selectedColor: const Color(0xFFE46A3E),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                          showCheckmark: false,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}