import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VouchersTab extends StatelessWidget {
  final String restaurantId;
  const VouchersTab({super.key, required this.restaurantId});

  void _showVoucherDialog(BuildContext context, [DocumentSnapshot? voucher]) {
    final bool isEditing = voucher != null;
    final codeController = TextEditingController(text: isEditing ? voucher['code'] : '');
    final discountController = TextEditingController(text: isEditing ? voucher['discount'].toString() : '');
    final limitController = TextEditingController(text: isEditing ? voucher['maxClaims'].toString() : '10');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? "Edit Voucher" : "Create Limited Voucher"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeController, decoration: const InputDecoration(labelText: "Promo Code (e.g. PROMO20)")),
            TextField(controller: discountController, decoration: const InputDecoration(labelText: "Discount Amount (%)"), keyboardType: TextInputType.number),
            TextField(controller: limitController, decoration: const InputDecoration(labelText: "Claim Limit (Number of Users)"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty && discountController.text.isNotEmpty) {
                final data = {
                  'code': codeController.text.toUpperCase().trim(),
                  'discount': int.tryParse(discountController.text) ?? 0,
                  'maxClaims': int.tryParse(limitController.text) ?? 10,
                  'currentClaims': isEditing ? voucher['currentClaims'] : 0,
                  'expiryDate': DateTime.now().add(const Duration(days: 7)),
                };

                if (isEditing) {
                  await voucher.reference.update(data);
                } else {
                  await FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(restaurantId)
                      .collection('vouchers')
                      .add(data);
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
        onPressed: () => _showVoucherDialog(context),
        backgroundColor: const Color(0xFFE46A3E),
        child: const Icon(Icons.add_card, color: Colors.white),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .collection('vouchers')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final vouchers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              var v = vouchers[index];
              int remaining = (v['maxClaims'] ?? 0) - (v['currentClaims'] ?? 0);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.confirmation_num, color: Colors.green),
                  title: Text("${v['code']} (${v['discount']}%)"),
                  subtitle: Text("Remaining: $remaining / ${v['maxClaims']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => v.reference.delete(),
                  ),
                  onLongPress: () => _showVoucherDialog(context, v),
                ),
              );
            },
          );
        },
      ),
    );
  }
}