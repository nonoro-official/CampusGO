import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ReviewModel>> getReviews(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ReviewModel.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> addReview(String businessId, ReviewModel review) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('reviews')
        .add(review.toMap());
  }
}