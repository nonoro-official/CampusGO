import 'package:unimart/models/enums.dart';

class InviteModel {
  final String inviteId;
  final String fromBusinessId;
  final String recipientEmail;
  final InviteStatus status; // 'pending' or 'accepted'

  InviteModel({
    required this.inviteId,
    required this.fromBusinessId,
    required this.recipientEmail,
    required this.status,
  });

  factory InviteModel.fromMap(Map<String, dynamic> data, String id) {
    return InviteModel(
      inviteId: id,
      fromBusinessId: data['fromBusinessId'] ?? '',
      recipientEmail: data['recipientEmail'] ?? '',
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromBusinessId': fromBusinessId,
      'recipientEmail': recipientEmail,
      'status': status,
    };
  }
}
