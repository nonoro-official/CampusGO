import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddRestaurantPage extends StatefulWidget {
  const AddRestaurantPage({super.key});

  @override
  State<AddRestaurantPage> createState() => _AddRestaurantPageState();
}

class _AddRestaurantPageState extends State<AddRestaurantPage> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  bool isLoading = false;

  void saveToDatabase() async {
    if (nameController.text.isEmpty || addressController.text.isEmpty) return;

    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('restaurants').add({
        'name': nameController.text.trim(),
        'address': addressController.text.trim(),
        'createdAt': DateTime.now(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Restaurant")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address")),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isLoading ? null : saveToDatabase,
              child: isLoading ? const CircularProgressIndicator() : const Text("Save Restaurant"),
            )
          ],
        ),
      ),
    );
  }
}