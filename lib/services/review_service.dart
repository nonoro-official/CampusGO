import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ReviewModel>> getReviews(String OrganizerId) {
    return _firestore
        .collection('Organizeres')
        .doc(OrganizerId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ReviewModel.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> addReview(String OrganizerId, ReviewModel review) async {
    await _firestore
        .collection('Organizeres')
        .doc(OrganizerId)
        .collection('reviews')
        .add(review.toMap());
  }
}