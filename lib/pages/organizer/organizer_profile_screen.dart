import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusgo/widgets/top_bar.dart';

import '../../models/organizer_model.dart';
import '../../models/reward_item_model.dart';
import '../../models/faq_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/organizer_provider.dart';
import '../../utils/organizer_utils.dart';
import '../../components/sheets/leave_review_sheet.dart';
import '../../pages/settings/organizer_edit.dart';
import '../rewards/reward_item_detail_screen.dart';
import '../../widgets/reward_image.dart';
import '../../components/sheets/report_organizer_sheet.dart';
import '../../models/enums.dart';
import '../messages/chat_page.dart';
import '../../services/message_service.dart';

class OrganizerProfileScreen extends ConsumerWidget {
  final OrganizerModel organizer;

  const OrganizerProfileScreen({super.key, required this.organizer});

  String formatPartner(OrganizerPartner partner) {
    return partner.name[0].toUpperCase() + partner.name.substring(1);
  }

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

  void _showFAQModal(BuildContext context, List<FAQModel> faqs) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Frequently Asked Questions",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 15),
              if (faqs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                      child: Text("No FAQs available for this Organizer.")),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: faqs.length,
                    itemBuilder: (context, index) {
                      final faq = faqs[index];
                      return ExpansionTile(
                        title: Text(
                          faq.question,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(faq.answer),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the live organizer data if we have it, otherwise fallback to the passed organizer object
    final organizerStream = ref.watch(organizerProvider(organizer.id));
    final currentOrganizer = organizerStream.value ?? organizer;

    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;
    final currentUser = ref.watch(currentUserProvider);
    final isOwnerViewing = currentUser?.uid == currentOrganizer.ownerId;

    final reviewsAsync =
        ref.watch(organizerReviewsProvider(currentOrganizer.id));
    final hasImage = currentOrganizer.imageUrl != null &&
        currentOrganizer.imageUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF5F5F5),
      appBar: TopBar(
        title: isOwnerViewing ? "My Organizer Profile" : "Organizer Profile",
        showBack: true,
        center: true,
        dashboard: !isOwnerViewing,
        messageReceiverId: currentOrganizer.ownerId,
        messageReceiverName: currentOrganizer.organizerName,
        messageReceiverImage: currentOrganizer.imageUrl,
        rightIcon: isOwnerViewing ? Icons.edit : Icons.chat_bubble_outline,
        onRightPressed: isOwnerViewing
            ? () => editOrganizerProfile(context, currentOrganizer, ref)
            : () async {
                // ✅ ensure chat room exists
                await MessageService()
                    .initiateContact(currentOrganizer.ownerId);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      receiverName: currentOrganizer.organizerName,
                      receiverID: currentOrganizer.ownerId,
                      receiverImageUrl: currentOrganizer.imageUrl,
                    ),
                  ),
                );
              },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Organizer HEADER
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                    backgroundImage: hasImage
                        ? NetworkImage(currentOrganizer.imageUrl!)
                        : null,
                    child: hasImage
                        ? null
                        : Icon(Icons.store, size: 40, color: primaryColor),
                  ),
                  const SizedBox(height: 12),

                  /// SHOP NAME
                  Text(currentOrganizer.organizerName,
                      style: textTheme.titleLarge),
                  const SizedBox(height: 6),

                  // PARTNER TYPE BADGE
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: getPartnerColor(currentOrganizer.organizerPartner)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getPartnerIcon(currentOrganizer.organizerPartner),
                          size: 16,
                          color: getPartnerColor(
                              currentOrganizer.organizerPartner),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatPartner(currentOrganizer.organizerPartner),
                          style: textTheme.bodySmall?.copyWith(
                            color: getPartnerColor(
                                currentOrganizer.organizerPartner),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// DESCRIPTION
                  Text(
                    currentOrganizer.description ?? "No description yet",
                    style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  if (!isOwnerViewing)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.flag),
                      label: const Text("Report Organizer"),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => ReportOrganizerSheet(
                            organizerId: currentOrganizer.id,
                            organizerName: currentOrganizer.organizerName,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// Organizer INFO
            _infoTile(
              Icons.phone,
              "Contact",
              Text(
                currentOrganizer.contactNumber.isEmpty
                    ? "-"
                    : currentOrganizer.contactNumber,
              ),
            ),
            _infoTile(
              Icons.email,
              "Email",
              Text(currentOrganizer.contactEmail.isEmpty
                  ? "-"
                  : currentOrganizer.contactEmail),
            ),
            _infoTile(
              Icons.help_outline,
              "FAQ",
              InkWell(
                onTap: () => _showFAQModal(context, currentOrganizer.faqs),
                child: Text(
                  "View Frequently Asked Questions",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            /// PRODUCTS SECTION
            _buildRewardsSection(currentOrganizer.id, context, ref),

            const SizedBox(height: 30),

            /// REVIEWS HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Customer Reviews",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isOwnerViewing)
                  ElevatedButton(
                    child: const Text("Leave Review"),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) =>
                            LeaveReviewSheet(organizerId: currentOrganizer.id),
                      );
                    },
                  ),
              ],
            ),

            const SizedBox(height: 10),

            /// REVIEWS LIST
            reviewsAsync.when(
              data: (reviews) {
                if (reviews.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(child: Text("No reviews yet")),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person),
                                const SizedBox(width: 8),
                                Text(
                                  review.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(review.comment),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text("Error loading reviews: $e"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildRewardsSection(
    String organizerId,
    BuildContext context,
    WidgetRef ref,
  ) {
    final rewardsAsync = ref.watch(organizerRewardsProvider(organizerId));
    final textTheme = Theme.of(context).textTheme;

    return rewardsAsync.when(
      data: (rewards) {
        if (rewards.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rewards', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  final reward = rewards[index];
                  return _rewardCard(reward, context, textTheme, rewards);
                },
              ),
            ),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rewards', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  static Widget _rewardCard(
    RewardModel reward,
    BuildContext context,
    TextTheme textTheme,
    List<RewardModel> allRewards,
  ) {
    final effectiveStock = reward.calculateEffectiveStock(allRewards);
    final isOutOfStock = effectiveStock <= 0;
    final isLowStock = effectiveStock > 0 && effectiveStock <= 9;
    final hasDiscount =
        reward.originalPoints != null && reward.originalPoints! > reward.points;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RewardDetailScreen(reward: reward),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              color: Colors.black12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            Stack(
              children: [
                RewardImage(
                  imageUrl: reward.imageUrl,
                  width: double.infinity,
                  height: 100,
                  borderRadius: 12,
                  isAvailable: !isOutOfStock,
                ),
                if (effectiveStock > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isLowStock ? Colors.orange : Colors.green)
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "$effectiveStock in stock",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            /// DETAILS
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${reward.points} pts',
                        style: textTheme.bodySmall?.copyWith(
                          color: hasDiscount
                              ? Colors.red
                              : Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasDiscount && reward.discountPercentage != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '-${reward.discountPercentage!.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// INFO TILE
  static Widget _infoTile(IconData icon, String title, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
