import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unimart/utils/online_utils.dart';

class OnlineStatus extends StatelessWidget {
  final String userId;

  const OnlineStatus({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null) return const SizedBox();

        final bool isOnline = isUserActuallyOnline(data);
        final lastSeenTimestamp = data['lastSeen'];

        if (isOnline) {
          return const Text(
            "Online",
            style: TextStyle(fontSize: 12, color: Colors.green),
          );
        }

        if (lastSeenTimestamp is Timestamp) {
          return Text(
            "Last seen ${formatLastSeen(lastSeenTimestamp)}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          );
        }

        return const SizedBox();
      },
    );
  }
}
