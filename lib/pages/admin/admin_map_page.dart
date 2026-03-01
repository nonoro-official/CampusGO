import 'package:flutter/material.dart';

class AdminMapPage extends StatelessWidget {
  const AdminMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map View")),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text("Map feature is temporarily disabled."),
            Text("API Configuration in progress.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}