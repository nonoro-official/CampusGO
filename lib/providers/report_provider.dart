import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final reportOrganizerProvider = Provider((ref) {
  return ReportOrganizerService();
});

class ReportOrganizerService {
  final _db = FirebaseFirestore.instance;

  Future<void> submitReport({
    required String reporterId,
    required String OrganizerId,
    required String OrganizerName,
    required String reason,
    required String description,
  }) async {
    await _db.collection('reports').add({
      'reporterId': reporterId,
      'OrganizerId': OrganizerId,
      'OrganizerName': OrganizerName,
      'reason': reason,
      'description': description,
      'timestamp': Timestamp.now(),
      'status': 'pending',
    });
  }
}