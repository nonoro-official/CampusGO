import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final reportBusinessProvider = Provider((ref) {
  return ReportBusinessService();
});

class ReportBusinessService {
  final _db = FirebaseFirestore.instance;

  Future<void> submitReport({
    required String reporterId,
    required String businessId,
    required String businessName,
    required String reason,
    required String description,
  }) async {
    await _db.collection('reports').add({
      'reporterId': reporterId,
      'businessId': businessId,
      'businessName': businessName,
      'reason': reason,
      'description': description,
      'timestamp': Timestamp.now(),
      'status': 'pending',
    });
  }
}