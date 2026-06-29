import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/review_model.dart';
import '../../providers/review_provider.dart';
import '../../providers/auth_provider.dart';

class LeaveReviewSheet extends ConsumerStatefulWidget {
  final String businessId;

  const LeaveReviewSheet({super.key, required this.businessId});

  @override
  ConsumerState<LeaveReviewSheet> createState() => _LeaveReviewSheetState();
}

class _LeaveReviewSheetState extends ConsumerState<LeaveReviewSheet> {
  double rating = 5;
  final TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Leave a Review",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          // Star Rating Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1.0;
              return IconButton(
                onPressed: () {
                  setState(() {
                    rating = starValue;
                  });
                },
                icon: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
              );
            }),
          ),

          Text(
            "${rating.toInt()} Stars",
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Comment (optional)",
              hintText: "Tell us about your experience...",
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Submit Review",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final service = ref.read(reviewServiceProvider);
                
                final String userId = currentUser?.uid ?? "anonymous";
                final String userName = currentUser != null 
                    ? "${currentUser.firstName} ${currentUser.lastName}".trim() 
                    : "Anonymous";

                final review = ReviewModel(
                  id: "",
                  userId: userId,
                  userName: userName.isEmpty ? "Customer" : userName,
                  rating: rating,
                  comment: commentController.text,
                  createdAt: DateTime.now(),
                );

                await service.addReview(widget.businessId, review);

                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
