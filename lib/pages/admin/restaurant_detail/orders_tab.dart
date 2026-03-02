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

        if (orders.isEmpty) {
          return const Center(child: Text("No orders received yet."));
        }

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
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Type: ${order['orderType'] ?? 'Dine-in'}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
                        Text(DateFormat('hh:mm a').format(date), style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const Divider(),
                    Text("Items: ${order['items']}", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),
                    Text("Total: ₱${order['total']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(isPaid ? "PAID" : "UNPAID",
                              style: TextStyle(color: isPaid ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold)),
                        ),
                        DropdownButton<String>(
                          value: status,
                          underline: Container(),
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