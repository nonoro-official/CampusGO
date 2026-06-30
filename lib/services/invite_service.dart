import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invite_model.dart';
import '../models/enums.dart';

class InviteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Vendor sends an invite to a co-vendor by email
  // Called from vendor dashboard
  Future<void> sendInvite({
    required String fromOrganizerId,
    required String recipientEmail,
  }) async {
    // Check if invite already exists for this email + Organizer
    final existing = await _db
        .collection('invites')
        .where('fromOrganizerId', isEqualTo: fromOrganizerId)
        .where('recipientEmail', isEqualTo: recipientEmail)
        .where('status', isEqualTo: InviteStatus.pending.name)
        .get();

    if (existing.docs.isNotEmpty) return; // don't send duplicates

    await _db.collection('invites').add({
      'fromOrganizerId': fromOrganizerId,
      'recipientEmail': recipientEmail,
      'status': InviteStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Co-vendor listens for pending invites sent to their email (real-time)
  // Called from pending_invite_screen.dart
  Stream<List<InviteModel>> getPendingInvites(String email) {
    return _db
        .collection('invites')
        .where('recipientEmail', isEqualTo: email)
        .where('status', isEqualTo: InviteStatus.pending.name)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => InviteModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Co-vendor accepts invite
  Future<void> acceptInvite({
    required String inviteId,
    required String fromOrganizerId,
    required String coVendorUserId,
  }) async {
    final batch = _db.batch();

    // 1. Update invite status to accepted
    batch.update(_db.collection('invites').doc(inviteId), {
      'status': InviteStatus.accepted.name,
    });

    // 2. Link co-vendor to Organizer
    batch.update(_db.collection('users').doc(coVendorUserId), {
      'organizerId': fromOrganizerId,
    });

    // 3. Add co-vendor to Organizer's coVendorIds list
    batch.update(_db.collection('Organizers').doc(fromOrganizerId), {
      'coVendorIds': FieldValue.arrayUnion([coVendorUserId]),
    });

    await batch.commit();
  }

  // Co-vendor declines invite
  Future<void> declineInvite(String inviteId) async {
    await _db.collection('invites').doc(inviteId).update({
      'status': InviteStatus.declined.name,
    });
  }
}
