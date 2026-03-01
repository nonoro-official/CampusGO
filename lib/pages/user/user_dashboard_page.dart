import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_map_page.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';

// NEW: Import the pages for the sidebar navigation
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

  // State variables for our search and filters
  String searchQuery = "";
  String activeFilter = "All";

  // The quick filters we want to show as pill buttons
  final List<String> quickFilters = ["All", "Filipino", "Fast Food", "Cafe", "₱ (Budget)", "Free WiFi"];

  void logout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Logout", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String uidSnippet = user?.uid.substring(0, 8).toUpperCase() ?? "00000000";
    final String userEmail = user?.email ?? "User";

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(userEmail, uidSnippet),
      body: Stack(
        children: [
          // 1. The Map (Now receives the search and filter data!)
          UserMapPage(searchQuery: searchQuery, activeFilter: activeFilter),

          // 2. The Floating Search & Filter Bar
          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Text Field
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black87),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => searchQuery = val), // Updates map as you type
                          decoration: const InputDecoration(hintText: "Search for restaurants...", border: InputBorder.none),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune, color: Color(0xFFE46A3E)),
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Advanced filters coming soon!"))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Horizontal Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  // Hides the scrollbar for a cleaner look
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: quickFilters.map((filter) {
                      bool isSelected = activeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                          selected: isSelected,
                          selectedColor: const Color(0xFFE46A3E),
                          backgroundColor: Colors.white,
                          showCheckmark: false,
                          onSelected: (selected) {
                            if (selected) setState(() => activeFilter = filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(String email, String uidSnippet) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFE46A3E)),
            accountName: Text(email.split('@')[0], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            accountEmail: Text("UID: $uidSnippet", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFFE46A3E), size: 40)),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]), borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.white),
              title: const Text("Upgrade to PRO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text("₱89/mo for exclusive perks", style: TextStyle(color: Colors.white70, fontSize: 12)),
              onTap: () {
                Navigator.pop(context); // Close the drawer first
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Premium Checkout UI coming soon!")));
              },
            ),
          ),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text("Personal Details"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalDetailsPage()));
              }
          ),
          ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Order History"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryPage()));
              }
          ),
          ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text("Saved Places"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlacesPage()));
              }
          ),
          ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings coming soon!")));
              }
          ),
          ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text("Help & Support"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Help & Support coming soon!")));
              }
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              onPressed: logout,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.logout),
              label: const Text("Log Out", style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}