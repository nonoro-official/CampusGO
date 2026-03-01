import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({super.key});

  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPageState();
}

class _PersonalDetailsPageState extends State<PersonalDetailsPage> {
  final user = FirebaseAuth.instance.currentUser;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    if (user != null) {
      // Guess name from email initially
      nameController.text = user!.email?.split('@')[0] ?? '';

      // Fetch actual data from Firestore if they saved it before
      var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        var data = doc.data()!;
        if (data.containsKey('name')) nameController.text = data['name'];
        if (data.containsKey('phone')) phoneController.text = data['phone'];
      }
    }
    setState(() => isLoading = false);
  }

  void _saveDetails() async {
    setState(() => isSaving = true);
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'email': user!.email,
    }, SetOptions(merge: true)); // Merge prevents overwriting other user data

    if (mounted) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uidSnippet = user?.uid.substring(0, 8).toUpperCase() ?? "00000000";

    return Scaffold(
      appBar: AppBar(title: const Text("Personal Details"), backgroundColor: const Color(0xFFE46A3E), foregroundColor: Colors.white),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: Color(0xFFFFE0B2), child: Icon(Icons.person, size: 60, color: Color(0xFFE46A3E))),
            const SizedBox(height: 10),
            Text("UID: $uidSnippet", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(
              controller: TextEditingController(text: user?.email),
              readOnly: true, // Email is tied to their auth account
              decoration: const InputDecoration(labelText: "Email Address", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone Number", hintText: "e.g. 0917 123 4567", border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: isSaving ? null : _saveDetails,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE46A3E), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}