import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReviewsTab extends StatelessWidget {
  final String restaurantId;
  const ReviewsTab({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
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
          return const Center(child: Text("No reviews yet. Be the first to rate!"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            var review = reviews[index].data();
            DateTime date = (review['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            double rating = (review['rating'] as num).toDouble();

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(5, (i) => Icon(
                            Icons.star,
                            size: 16,
                            color: i < rating ? Colors.amber : Colors.grey.shade300,
                          )),
                        ),
                        Text(DateFormat('MMM dd, yyyy').format(date),
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(review['comment'] ?? '', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 5),
                    Text("— ${review['userName'] ?? 'Anonymous'}",
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}