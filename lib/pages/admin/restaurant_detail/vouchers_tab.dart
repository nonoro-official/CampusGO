import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VouchersTab extends StatelessWidget {
  final String restaurantId;
  const VouchersTab({super.key, required this.restaurantId});

  void _showVoucherDialog(BuildContext context, [DocumentSnapshot? voucher]) {
    final bool isEditing = voucher != null;

    // SAFE CASTING: Safely pull data from old vouchers so the app never crashes
    final data = isEditing ? voucher.data() as Map<String, dynamic> : <String, dynamic>{};

    final codeController = TextEditingController(text: isEditing ? (data['code'] ?? '') : '');
    final discountController = TextEditingController(text: isEditing ? (data['discount']?.toString() ?? '') : '');
    final limitController = TextEditingController(text: isEditing ? (data['maxClaims']?.toString() ?? '10') : '10');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? "Edit Voucher" : "Create Limited Voucher"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeController, decoration: const InputDecoration(labelText: "Promo Code (e.g. PROMO20)")),
            const SizedBox(height: 10),
            TextField(controller: discountController, decoration: const InputDecoration(labelText: "Discount Amount (%)"), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: limitController, decoration: const InputDecoration(labelText: "Claim Limit (Number of Users)"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty && discountController.text.isNotEmpty) {
                final updateData = {
                  'code': codeController.text.toUpperCase().trim(),
                  'discount': int.tryParse(discountController.text) ?? 0,
                  'maxClaims': int.tryParse(limitController.text) ?? 10,
                  'currentClaims': isEditing ? (data['currentClaims'] ?? 0) : 0,
                  'expiryDate': DateTime.now().add(const Duration(days: 7)),
                };

                if (isEditing) {
                  await voucher.reference.update(updateData);
                } else {
                  await FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(restaurantId)
                      .collection('vouchers')
                      .add(updateData);
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE46A3E), foregroundColor: Colors.white),
            child: Text(isEditing ? "Save Changes" : "Create Voucher"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVoucherDialog(context),
        backgroundColor: const Color(0xFFE46A3E),
        icon: const Icon(Icons.add_card, color: Colors.white),
        label: const Text("New Voucher", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

          if (vouchers.isEmpty) {
            return const Center(child: Text("No vouchers created yet.\nTap 'New Voucher' to add one!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              var v = vouchers[index];
              var data = v.data() as Map<String, dynamic>;

              // Safe fallbacks for the math
              int maxClaims = data.containsKey('maxClaims') ? data['maxClaims'] : 10;
              int currentClaims = data.containsKey('currentClaims') ? data['currentClaims'] : 0;
              int remaining = maxClaims - currentClaims;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(Icons.local_offer, color: Colors.green),
                  ),
                  title: Text("${data['code']} (${data['discount']}%)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text("Remaining: $remaining / $maxClaims\nLong-press to edit"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      // Added a confirmation dialog so you don't accidentally delete vouchers!
                      bool? confirm = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                              title: const Text("Delete Voucher"),
                              content: const Text("Are you sure you want to delete this voucher?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                              ]
                          )
                      );
                      if (confirm == true) {
                        v.reference.delete();
                      }
                    },
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