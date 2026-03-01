import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_restaurant_page.dart';
// Import your new Detail Dashboard
import 'restaurant_detail/restaurant_detail_dashboard.dart';

class RestaurantListPage extends StatelessWidget {
  const RestaurantListPage({super.key});

  // Helper function for the Delete Confirmation
  void _confirmDelete(BuildContext context, DocumentReference docRef, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Restaurant"),
        content: Text("Are you sure you want to remove '$name'? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              docRef.delete(); // Deletes from Firestore
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Restaurants"),
        backgroundColor: const Color(0xFFE46A3E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No restaurants added yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 2,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFE0B2),
                    child: Icon(Icons.restaurant, color: Colors.orange),
                  ),
                  title: Text(data['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['address'] ?? 'No Address'),
                  // TAP TO VIEW DETAILS
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantDetailDashboard(
                          restaurantId: doc.id,
                          restaurantData: data,
                        ),
                      ),
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, doc.reference, data['name'] ?? 'this place'),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE46A3E),
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRestaurantPage())
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}