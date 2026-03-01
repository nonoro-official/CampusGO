import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VouchersTab extends StatelessWidget {
  final String restaurantId;
  const VouchersTab({super.key, required this.restaurantId});

  // Now accepts an optional DocumentSnapshot for editing
  void _showVoucherDialog(BuildContext context, [DocumentSnapshot? voucher]) {
    final bool isEditing = voucher != null;
    final codeController = TextEditingController(text: isEditing ? voucher['code'] : '');
    final discountController = TextEditingController(text: isEditing ? voucher['discount'].toString() : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? "Edit Voucher" : "Create New Voucher"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: "Promo Code (e.g. SAVE20)"),
            ),
            TextField(
              controller: discountController,
              decoration: const InputDecoration(labelText: "Discount Amount (%)"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty && discountController.text.isNotEmpty) {
                if (isEditing) {
                  // UPDATE existing
                  await voucher.reference.update({
                    'code': codeController.text.toUpperCase().trim(),
                    'discount': int.tryParse(discountController.text) ?? 0,
                  });
                } else {
                  // ADD new
                  await FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(restaurantId)
                      .collection('vouchers')
                      .add({
                    'code': codeController.text.toUpperCase().trim(),
                    'discount': int.tryParse(discountController.text) ?? 0,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(isEditing ? "Save" : "Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVoucherDialog(context), // Trigger Add Mode
        backgroundColor: const Color(0xFFE46A3E),
        child: const Icon(Icons.add_card, color: Colors.white),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .collection('vouchers')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final vouchers = snapshot.data!.docs;

          if (vouchers.isEmpty) {
            return const Center(child: Text("No vouchers available for this place."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              var voucher = vouchers[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.confirmation_num, color: Colors.green),
                  title: Text(voucher['code'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${voucher['discount']}% Discount"),
                  // Wrap icons in a Row for Edit and Delete
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showVoucherDialog(context, voucher), // Trigger Edit Mode
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Delete Voucher"),
                              content: const Text("Are you sure?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes", style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            voucher.reference.delete();
                          }
                        },
                      ),
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