import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Text Controllers for user input
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  String? errorMessage;
  bool isLoading = false;

  /// Handles both Firebase Authentication and Firestore Database entry
  void register() async {
    // 1. Basic Validation
    if (passwordController.text != confirmController.text) {
      setState(() => errorMessage = "Passwords do not match.");
      return;
    }

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() => errorMessage = "Please fill in all fields.");
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': emailController.text.trim(),
        'role': 'user',
        'createdAt': DateTime.now(),
      });

      if (mounted) Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message ?? "An error occurred.");
    } catch (e) {
      setState(() => errorMessage = "Database error: Could not save profile.");
    }

    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Foodika Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Icon(Icons.restaurant_menu, size: 80, color: Colors.green),
            const SizedBox(height: 20),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : register,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}