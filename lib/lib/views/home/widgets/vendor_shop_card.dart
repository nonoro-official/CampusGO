import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/review_provider.dart';
import '../../home/vendor_profile_screen.dart';
import '../../../utils/business_utils.dart';
import '../../../models/enums.dart';

class VendorShopCard extends ConsumerWidget {
  const VendorShopCard({super.key});

  String formatPartner(BusinessPartner partner) {
    return partner.name[0].toUpperCase() +
        partner.name.substring(1);
  }

  // icon per partner type
  IconData getPartnerIcon(BusinessPartner partner) {
    switch (partner) {
      case BusinessPartner.campus:
        return Icons.school;
      case BusinessPartner.organization:
        return Icons.groups;
      case BusinessPartner.student:
        return Icons.person;
    }
  }

  // color per partner type
  Color getPartnerColor(BusinessPartner partner) {
    switch (partner) {
      case BusinessPartner.campus:
        return Colors.blue;
      case BusinessPartner.organization:
        return Colors.green;
      case BusinessPartner.student:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    final businessAsync = ref.watch(myBusinessProvider);

    return businessAsync.when(
      data: (business) {
        if (business == null) return const SizedBox.shrink();

        final reviewsAsync = ref.watch(businessReviewsProvider(business.id));
        final isOpen = isBusinessActuallyOpen(business.businessHours);
        final hasImage =
            business.imageUrl != null && business.imageUrl!.isNotEmpty;

        return reviewsAsync.when(
          data: (reviews) {
            double avgRating = 0;
            int totalReviews = reviews.length;

            if (reviews.isNotEmpty) {
              final sum = reviews.map((r) => r.rating).reduce((a, b) => a + b);
              avgRating = sum / reviews.length;
            }

            final partnerColor = getPartnerColor(business.businessPartner);

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
                      /// Store icon or Business Image
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        backgroundImage: hasImage
                            ? NetworkImage(business.imageUrl!)
                            : null,
                        child: hasImage
                            ? null
                            : Icon(Icons.store, color: primaryColor),
                      ),
                      const SizedBox(width: 16),

                      /// Business info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              business.businessName,
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
                                    getPartnerIcon(business.businessPartner),
                                    size: 14,
                                    color: partnerColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    formatPartner(
                                        business.businessPartner),
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

                            const SizedBox(height: 6),

                            /// Status
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: isOpen ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOpen ? "Open" : "Closed",
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isOpen ? Colors.green : Colors.red,
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
                                    VendorProfileScreen(business: business),
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