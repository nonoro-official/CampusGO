import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

final reviewServiceProvider = Provider((ref) {
  return ReviewService();
});

final OrganizerReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, OrganizerId) {
  final service = ref.watch(reviewServiceProvider);
  return service.getReviews(OrganizerId);
});