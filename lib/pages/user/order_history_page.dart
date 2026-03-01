import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Add 'intl' to your pubspec.yaml for date formatting

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Order History"), backgroundColor: const Color(0xFFE46A3E), foregroundColor: Colors.white),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("You haven't placed any orders yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final order = docs[index].data();
              bool isCompleted = order["status"] == "Completed";
              DateTime date = (order['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(order["restaurantName"] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("₱${order["total"]}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(DateFormat('MMM dd, yyyy – hh:mm a').format(date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const Divider(height: 20),
                      Text(order["items"] ?? '', style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          order["status"] ?? 'Pending',
                          style: TextStyle(color: isCompleted ? Colors.green.shade800 : Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}