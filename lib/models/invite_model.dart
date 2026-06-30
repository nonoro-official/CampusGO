import 'enums.dart';

class InviteModel {
  final String inviteId;
  final String fromOrganizerId;
  final String recipientEmail;
  final InviteStatus status; // 'pending' or 'accepted'

  InviteModel({
    required this.inviteId,
    required this.fromOrganizerId,
    required this.recipientEmail,
    required this.status,
  });

  factory InviteModel.fromMap(Map<String, dynamic> data, String id) {
    return InviteModel(
      inviteId: id,
      fromOrganizerId: data['fromOrganizerId'] ?? '',
      recipientEmail: data['recipientEmail'] ?? '',
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromOrganizerId': fromOrganizerId,
      'recipientEmail': recipientEmail,
      'status': status,
    };
  }
}
