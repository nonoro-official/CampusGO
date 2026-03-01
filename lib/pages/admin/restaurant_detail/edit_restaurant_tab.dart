import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditRestaurantTab extends StatefulWidget {
  final String restaurantId;
  final Map<String, dynamic> data;
  const EditRestaurantTab({super.key, required this.restaurantId, required this.data});

  @override
  State<EditRestaurantTab> createState() => _EditRestaurantTabState();
}

class _EditRestaurantTabState extends State<EditRestaurantTab> {
  late TextEditingController nameController;
  late TextEditingController addressController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data['name']);
    addressController = TextEditingController(text: widget.data['address']);
  }

  void applyChanges() async {
    setState(() => isSaving = true);
    try {
      // 1. Update main details
      await FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).update({
        'name': nameController.text.trim(),
        'address': addressController.text.trim(),
      });

      // 2. Log to History Sub-collection
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('history')
          .add({
        'action': 'Details Updated',
        'details': 'Changed name/address',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Changes Applied!")));
    } catch (e) {
      debugPrint(e.toString());
    }
    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(controller: nameController, decoration: const InputDecoration(labelText: "Restaurant Name")),
          TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address")),
          const Spacer(),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Discard")
                  )
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : applyChanges,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: isSaving ? const CircularProgressIndicator() : const Text("Apply Changes"),
                  )
              ),
            ],
          )
        ],
      ),
    );
  }
}