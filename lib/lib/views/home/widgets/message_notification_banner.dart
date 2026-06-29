import 'package:flutter/material.dart';

class MessageNotificationBanner extends StatelessWidget {
  final String senderName;
  final String message;
  final VoidCallback onTap;

  const MessageNotificationBanner({
    super.key,
    required this.senderName,
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary,
                  child: const Icon(Icons.message, color: Colors.white),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),

                Icon(Icons.chevron_right, color: primary)
              ],
            ),
          ),
        ),
      ),
    );
  }
}