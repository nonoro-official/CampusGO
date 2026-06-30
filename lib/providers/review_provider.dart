import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

final reviewServiceProvider = Provider((ref) {
  return ReviewService();
});

final businessReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, businessId) {
  final service = ref.watch(reviewServiceProvider);
  return service.getReviews(businessId);
});