import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrdersTab extends StatelessWidget {
  final String restaurantId;
  const OrdersTab({super.key, required this.restaurantId});

  Future<void> _updateOrderStatus(BuildContext context, String docId, Map<String, dynamic> order, String newStatus) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Order Status"),
        content: Text("Are you sure you want to change the status to '$newStatus'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE46A3E), foregroundColor: Colors.white),
            child: const Text("Yes, Update"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updating status..."), duration: Duration(seconds: 1)));

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('orders')
          .doc(docId)
          .update({'status': newStatus});

      String? userId = order['userId'];
      if (userId != null && userId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(docId)
            .update({'status': newStatus});

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Status updated for both Admin and User!"), backgroundColor: Colors.green)
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Warning: 'userId' is missing in this order. The user's app will NOT be updated!"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            )
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

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
            var order = orders[index].data() as Map<String, dynamic>;
            var docId = orders[index].id;
            DateTime date = (order['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            String status = order['status'] ?? 'Pending';
            bool isPaid = order['isPaid'] ?? false;

            // NEW: Fetch the orderType (Fallback to 'Dine-in' if missing)
            String orderType = order['orderType'] ?? 'Dine-in';

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Order ID: ${docId.substring(0, 8)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(DateFormat('MMM dd, yyyy - hh:mm a').format(date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 20),

                    // NEW: Display Customer Name alongside the Order Type Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text("Customer: ${order['userName'] ?? 'Guest'}", style: const TextStyle(fontSize: 15)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            // Purple for Takeout, Blue for Dine-in
                              color: orderType == 'Takeout' ? Colors.purple.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: orderType == 'Takeout' ? Colors.purple.shade200 : Colors.blue.shade200,
                              )
                          ),
                          child: Row(
                            children: [
                              Icon(
                                  orderType == 'Takeout' ? Icons.shopping_bag_outlined : Icons.restaurant,
                                  size: 16,
                                  color: orderType == 'Takeout' ? Colors.purple.shade700 : Colors.blue.shade700
                              ),
                              const SizedBox(width: 6),
                              Text(
                                  orderType,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: orderType == 'Takeout' ? Colors.purple.shade700 : Colors.blue.shade700
                                  )
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text("Total: ₱${order['totalAmount']?.toStringAsFixed(2) ?? '0.00'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text("Payment: "),
                        Text(isPaid ? "Paid" : "Pending", style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Update Status:", style: TextStyle(fontWeight: FontWeight.w500)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: status,
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFE46A3E)),
                              onChanged: (String? newValue) {
                                if (newValue != null && newValue != status) {
                                  _updateOrderStatus(context, docId, order, newValue);
                                }
                              },
                              items: <String>['Pending', 'Preparing', 'Done', 'Cancelled']
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: value == 'Done' ? Colors.green : (value == 'Cancelled' ? Colors.red : Colors.orange)
                                  )),
                                );
                              }).toList(),
                            ),
                          ),
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