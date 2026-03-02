import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrdersTab extends StatelessWidget {
  final String restaurantId;
  const OrdersTab({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('orders')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!.docs;

        if (orders.isEmpty) return const Center(child: Text("No current orders."));

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            var order = orders[index].data();
            var docId = orders[index].id;
            DateTime date = (order['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            String status = order['status'] ?? 'Pending';
            bool isPaid = order['isPaid'] ?? false;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${order['orderType']} ORDER",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE46A3E), fontSize: 16)),
                        Text(DateFormat('hh:mm a').format(date), style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const Divider(height: 20),
                    Text("Items: ${order['items']}", style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total: ₱${order['total']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(isPaid ? "PAID ✅" : "UNPAID ❌",
                            style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Update Status:", style: TextStyle(fontWeight: FontWeight.w500)),
                        DropdownButton<String>(
                          value: status,
                          onChanged: (String? newValue) {
                            FirebaseFirestore.instance
                                .collection('restaurants')
                                .doc(restaurantId)
                                .collection('orders')
                                .doc(docId)
                                .update({'status': newValue});
                          },
                          items: <String>['Pending', 'Preparing', 'Done', 'Cancelled']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}