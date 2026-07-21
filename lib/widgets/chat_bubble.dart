import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final DateTime? sentAt;

  const ChatBubble(
      {required this.message,
      required this.isCurrentUser,
      this.sentAt,
      super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final receivedBackground = theme.brightness == Brightness.dark
        ? colors.surfaceContainerHigh
        : Colors.grey.shade300;
    final receivedText =
        theme.brightness == Brightness.dark ? colors.onSurface : Colors.black87;
    final receivedTimestamp = theme.brightness == Brightness.dark
        ? colors.onSurfaceVariant
        : Colors.black54;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blueAccent : receivedBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isCurrentUser
                ? const Radius.circular(16)
                : const Radius.circular(0),
            bottomRight: isCurrentUser
                ? const Radius.circular(0)
                : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : receivedText,
              ),
            ),
            if (sentAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  "${sentAt!.hour.toString().padLeft(2, '0')}:${sentAt!.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white70 : receivedTimestamp,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
