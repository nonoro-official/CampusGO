import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  void _showReviewDialog(BuildContext context, String restaurantId, String restaurantName, String orderId) {
    double selectedRating = 5;
    final commentController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Rate $restaurantName"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("How was your experience?"),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 30,
                  ),
                  onPressed: () => setState(() => selectedRating = index + 1.0),
                )),
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: "Write a comment...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Later")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE46A3E)),
              onPressed: () async {
                if (user == null) return;

                final restaurantRef = FirebaseFirestore.instance.collection('restaurants').doc(restaurantId);
                final reviewRef = restaurantRef.collection('reviews').doc(); // Auto-generate ID for the review

                try {
                  // Use a transaction to safely update averages and counts
                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                    DocumentSnapshot snapshot = await transaction.get(restaurantRef);

                    if (!snapshot.exists) {
                      throw Exception("Restaurant does not exist!");
                    }

                    // Get current stats (default to 0 if they don't exist yet)
                    double currentTotalRating = (snapshot.data() as Map<String, dynamic>)['totalRatingSum']?.toDouble() ?? 0.0;
                    int currentReviewCount = (snapshot.data() as Map<String, dynamic>)['reviewCount']?.toInt() ?? 0;

                    // Calculate new stats
                    double newTotalRatingSum = currentTotalRating + selectedRating;
                    int newReviewCount = currentReviewCount + 1;
                    double newAverage = newTotalRatingSum / newReviewCount;

                    // 1. Add the Review document to the sub-collection
                    transaction.set(reviewRef, {
                      'rating': selectedRating,
                      'comment': commentController.text.trim(),
                      'userName': user.email?.split('@')[0] ?? 'User',
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    // 2. Update the main Restaurant document
                    transaction.update(restaurantRef, {
                      'avgRating': double.parse(newAverage.toStringAsFixed(1)),
                      'reviewCount': newReviewCount,
                      'totalRatingSum': newTotalRatingSum,
                    });

                    // 3. NEW: Mark this specific order as rated so they can't spam!
                    final userOrderRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('orders').doc(orderId);
                    transaction.update(userOrderRef, {'isRated': true});
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Review submitted! Thank you."), backgroundColor: Colors.green)
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to submit review: $e"), backgroundColor: Colors.red)
                    );
                  }
                }
              },
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
          title: const Text("Order History"),
          backgroundColor: const Color(0xFFE46A3E),
          foregroundColor: Colors.white
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No orders found."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final order = docs[index].data();
              final String orderId = docs[index].id;
              String status = order["status"] ?? 'Pending';
              bool isDone = status == "Done";
              bool isRated = order['isRated'] ?? false;
              DateTime date = (order['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(order["restaurantName"] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("₱${order["total"]}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text("Type: ${order['orderType'] ?? 'Dine-in'}",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      const Divider(height: 25),
                      Text(order["items"] ?? '', style: TextStyle(color: Colors.grey.shade800)),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDone ? Colors.green.shade100 : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                  color: isDone ? Colors.green.shade800 : Colors.orange.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          // ONLY SHOW REVIEW BUTTON IF ORDER IS DONE AND NOT RATED
                          if (isDone && !isRated)
                            ElevatedButton.icon(
                              onPressed: () => _showReviewDialog(
                                  context,
                                  order['restaurantId'],
                                  order['restaurantName'],
                                  orderId // Pass the ID here!
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              icon: const Icon(Icons.star, size: 16),
                              label: const Text("Rate Meal"),
                            )
                          else if (isDone && isRated)
                            const Text("⭐ Rated", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      )
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