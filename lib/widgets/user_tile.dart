import 'package:flutter/material.dart';
import 'package:campusgo/utils/online_utils.dart';

class UserTile extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final bool isOnline;
  final dynamic lastSeen;
  final VoidCallback onTap;
  final bool isUnread;

  const UserTile({
    required this.displayName,
    this.avatarUrl,
    required this.isOnline,
    required this.lastSeen,
    required this.onTap,
    this.isUnread = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    final bool actuallyOnline = isUserActuallyOnline({
      'isOnline': isOnline,
      'lastSeen': lastSeen,
    });

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.blueAccent,
              backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
              child: hasAvatar
                  ? null
                  : Text(
                      displayName.isNotEmpty ? displayName[0] : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
            ),

            // RED DOT (unread indicator)
            if (isUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),

        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: actuallyOnline
            ? const Text('Online', style: TextStyle(color: Colors.green))
            : lastSeen != null
                ? Text(
                    'Last seen ${formatLastSeen(lastSeen)}',
                    style: const TextStyle(color: Colors.grey),
                  )
                : null,
        trailing: actuallyOnline
            ? const Icon(Icons.circle, color: Colors.green, size: 12)
            : null,
      ),
    );
  }
}