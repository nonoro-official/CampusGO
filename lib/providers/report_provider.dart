import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final reportOrganizerProvider = Provider((ref) {
  return ReportOrganizerService();
});

class ReportOrganizerService {
  final _db = FirebaseFirestore.instance;

  Future<void> submitReport({
    required String reporterId,
    required String organizerId,
    required String organizerName,
    required String reason,
    required String description,
  }) async {
    await _db.collection('reports').add({
      'reporterId': reporterId,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'reason': reason,
      'description': description,
      'timestamp': Timestamp.now(),
      'status': 'pending',
    });
  }
}