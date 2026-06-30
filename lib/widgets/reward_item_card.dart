import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/organizer_provider.dart';
import '../../../providers/review_provider.dart';
import '../pages/organizer/organizer_profile_screen.dart';
import '../../../utils/organizer_utils.dart';
import '../../../models/enums.dart';

class OrganizerShopCard extends ConsumerWidget {
  const OrganizerShopCard({super.key});

  String formatPartner(OrganizerPartner partner) {
    return partner.name[0].toUpperCase() +
        partner.name.substring(1);
  }

  // icon per partner type
  IconData getPartnerIcon(OrganizerPartner partner) {
    switch (partner) {
      case OrganizerPartner.campus:
        return Icons.school;
      case OrganizerPartner.organization:
        return Icons.groups;
      case OrganizerPartner.student:
        return Icons.person;
    }
  }

  // color per partner type
  Color getPartnerColor(OrganizerPartner partner) {
    switch (partner) {
      case OrganizerPartner.campus:
        return Colors.blue;
      case OrganizerPartner.organization:
        return Colors.green;
      case OrganizerPartner.student:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    final organizerAsync = ref.watch(myOrganizerProvider);

    return organizerAsync.when(
      data: (organizer) {
        if (organizer == null) return const SizedBox.shrink();

        final reviewsAsync = ref.watch(OrganizerReviewsProvider(organizer.id));
        final hasImage =
            organizer.imageUrl != null && organizer.imageUrl!.isNotEmpty;

        return reviewsAsync.when(
          data: (reviews) {
            double avgRating = 0;
            int totalReviews = reviews.length;

            if (reviews.isNotEmpty) {
              final sum = reviews.map((r) => r.rating).reduce((a, b) => a + b);
              avgRating = sum / reviews.length;
            }

            final partnerColor = getPartnerColor(organizer.organizerPartner);

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
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Store icon or Organizer Image
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        backgroundImage: hasImage
                            ? NetworkImage(organizer.imageUrl!)
                            : null,
                        child: hasImage
                            ? null
                            : Icon(Icons.store, color: primaryColor),
                      ),
                      const SizedBox(width: 16),

                      /// Organizer info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              organizer.organizerName,
                              style: textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 6),

                            // Partner type
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: partnerColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    getPartnerIcon(organizer.organizerPartner),
                                    size: 14,
                                    color: partnerColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    formatPartner(
                                        organizer.organizerPartner),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: partnerColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 6),

                            /// Rating Row
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  avgRating.toStringAsFixed(1),
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "($totalReviews reviews)",
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// Profile Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    OrganizerProfileScreen(organizer: organizer),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 20,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(20),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Container(
            padding: const EdgeInsets.all(20),
            child: Text("Error loading rating: $err"),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text("Error: $err"),
    );
  }
}