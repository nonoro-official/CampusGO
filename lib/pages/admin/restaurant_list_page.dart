import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantListPage extends StatelessWidget {
  const RestaurantListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Restaurant List")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("restaurants").snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final data = docs[index];

              return Card(
                child: Column(
                  children: [
                    Expanded(
                      child: Image.network(data["imageUrl"], fit: BoxFit.cover),
                    ),
                    Text(data["name"]),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection("restaurants")
                            .doc(data.id)
                            .delete();
                      },
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}