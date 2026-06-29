import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final DateTime? sentAt;
  final bool isSeen;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.sentAt,
    this.isSeen = false,
  });

  String _formatTimestamp(BuildContext context, DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    final isToday = localDateTime.year == now.year &&
        localDateTime.month == now.month &&
        localDateTime.day == now.day;

    final isYesterday = localDateTime.year == yesterday.year &&
        localDateTime.month == yesterday.month &&
        localDateTime.day == yesterday.day;

    final time = TimeOfDay.fromDateTime(localDateTime).format(context);
    if (isToday) {
      return time;
    }
    if (isYesterday) {
      return 'Yesterday • $time';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[localDateTime.month - 1];
    return '$month ${localDateTime.day}, ${localDateTime.year} • $time';
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = sentAt != null ? _formatTimestamp(context, sentAt!) : '';

    return Column(
      crossAxisAlignment:
          isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.blue : Colors.grey,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(16),
          child: Text(message, style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (formattedTime.isNotEmpty)
              Text(
                formattedTime,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                ),
              ),
            if (isCurrentUser) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.done_all,
                size: 14,
                color: isSeen ? Colors.blue : Colors.grey,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
