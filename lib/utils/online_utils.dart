import 'package:cloud_firestore/cloud_firestore.dart';

String formatLastSeen(dynamic lastSeen) {
  if (lastSeen == null) return 'a long time ago';
  
  DateTime? date;

  if (lastSeen is Timestamp) {
    date = lastSeen.toDate();
  } else if (lastSeen is DateTime) {
    date = lastSeen;
  }

  if (date != null) {
    final difference = DateTime.now().difference(date);
    
    // Handle cases where clock might be slightly out of sync or just updated
    if (difference.isNegative || difference.inSeconds < 60) {
      return 'just now';
    }
    
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  // If it's not null but not a recognized date type (like a pending FieldValue),
  // it means it's being updated right now.
  return 'just now';
}

bool isUserActuallyOnline(Map<String, dynamic>? data) {
  if (data == null) return false;
  final bool isOnline = data['isOnline'] ?? false;
  final dynamic lastSeen = data['lastSeen'] ?? data['lastOnline'];

  if (!isOnline) return false;

  DateTime? date;
  if (lastSeen is Timestamp) {
    date = lastSeen.toDate();
  } else if (lastSeen is DateTime) {
    date = lastSeen;
  }

  if (date != null) {
    final difference = DateTime.now().difference(date);
    // If the last heartbeat was within 5 minutes, consider them online
    // Also handle negative difference (local clock behind server)
    return difference.inMinutes < 5;
  }

  // If we have an isOnline flag but no timestamp yet (pending), assume online
  return true;
}
