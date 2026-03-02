import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReviewsTab extends StatelessWidget {
  final String restaurantId;
  const ReviewsTab({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final reviews = snapshot.data!.docs;

          if (reviews.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No reviews yet from customers.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              var review = reviews[index].data();
              double rating = (review['rating'] ?? 0.0).toDouble();
              DateTime date = (review['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              );
                            }),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy').format(date),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        review['comment'] ?? 'No written comment provided.',
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "— ${review['userName'] ?? 'Anonymous'}",
                        style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFFE46A3E),
                            fontWeight: FontWeight.bold
                        ),
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