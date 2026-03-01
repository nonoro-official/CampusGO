import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  String? errorMessage;
  bool isLoading = false;

  void register() async {

    if (passwordController.text != confirmController.text) {
      setState(() {
        errorMessage = "Passwords do not match.";
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message  ?? "An error occurred. Please try again.";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm Password"),
            ),

            const SizedBox(height: 20),

            if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: isLoading ? null : register,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}