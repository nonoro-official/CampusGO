import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';

class WelcomeCard extends ConsumerWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    // Watch the user provider
    final user = ref.watch(currentUserProvider);

    if (user == null) return const SizedBox.shrink();

    final hasImage = user.imageUrl != null && user.imageUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: primaryColor.withValues(alpha: 0.2),
            backgroundImage: hasImage ? NetworkImage(user.imageUrl!) : null,
            child: hasImage ? null : Icon(Icons.person, color: primaryColor),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back, ${user.firstName}!", // Real Data
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                user.role.name.toUpperCase(), // Real Data from Enum
                style: textTheme.titleSmall?.copyWith(color: primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
