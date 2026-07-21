import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/search.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/reward_image.dart';
import '../../widgets/filter.dart';
import '../../providers/organizer_provider.dart';
import '../../providers/reward_provider.dart';
import '../../models/organizer_model.dart';
// import '../../utils/organizer_utils.dart';
import '../organizer/organizer_profile_screen.dart';

class ShopsScreen extends ConsumerStatefulWidget {
  const ShopsScreen({super.key});

  @override
  ConsumerState<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends ConsumerState<ShopsScreen> {
  String searchQuery = "";
  String selectedPartner = "All";

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const titleLabel = "All Shops";
    final allOrganizersAsync = ref.watch(allOrganizersProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF5F5F5),
      appBar: TopBar(
        title: 'CampusGO',
        showBack: true,
        rightIcon: Icons.chat_bubble_outline,
        onRightPressed: () => Navigator.pushNamed(context, "/messages"),
        center: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            /// TITLE
            Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(titleLabel, style: textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text("Browse organizers", style: textTheme.bodySmall),
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// PARTNER FILTER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FilterWidget(
                options: const ["All", "Campus", "Organization", "Student"],
                selectedValue: selectedPartner,
                onChanged: (val) {
                  setState(() {
                    selectedPartner = val ?? "All";
                  });
                },
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: allOrganizersAsync.when(
                data: (organizers) {
                  final filteredOrganizers = organizers.where((v) {
                    final matchesSearch = v.organizerName
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase());

                    final matchesPartner = selectedPartner == "All" ||
                        v.organizerPartner.name.toLowerCase() ==
                            selectedPartner.toLowerCase();

                    return matchesSearch && matchesPartner;
                  }).toList();

                  return Stack(
                    children: [
                      filteredOrganizers.isEmpty
                          ? const Center(child: Text("No organizers found"))
                          : OrganizerFeed(organizers: filteredOrganizers),
                      Positioned(
                        bottom: 10,
                        right: 0,
                        child: SearchButton(
                          dark: false,
                          onSearch: (val) => setState(() => searchQuery = val),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text("Error: $err")),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class OrganizerFeed extends StatelessWidget {
  final List<OrganizerModel> organizers;

  const OrganizerFeed({super.key, required this.organizers});

  @override
  Widget build(BuildContext context) {
    if (organizers.isEmpty) {
      return const Center(child: Text("No organizers found"));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: organizers.length,
      itemBuilder: (context, index) {
        return OrganizerCard(organizer: organizers[index]);
      },
    );
  }
}

class OrganizerCard extends ConsumerWidget {
  final OrganizerModel organizer;

  const OrganizerCard({super.key, required this.organizer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    final rewardsAsync = ref.watch(organizerRewardsProvider(organizer.id));
    final hasImage =
        organizer.imageUrl != null && organizer.imageUrl!.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrganizerProfileScreen(organizer: organizer),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                  backgroundImage:
                      hasImage ? NetworkImage(organizer.imageUrl!) : null,
                  child:
                      hasImage ? null : Icon(Icons.store, color: primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(organizer.organizerName,
                          style: textTheme.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            rewardsAsync.when(
              data: (rewards) {
                if (rewards.isEmpty) {
                  return Text(
                    organizer.description ?? "No description available.",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  );
                }

                return SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: rewards.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final reward = rewards[index];

                      final effectiveStock =
                          reward.calculateEffectiveStock(rewards);

                      return Stack(
                        children: [
                          RewardImage(
                            imageUrl: reward.imageUrl,
                            width: 90,
                            height: 90,
                            borderRadius: 12,
                            isAvailable: effectiveStock > 0,
                          ),
                          if (effectiveStock > 0 && effectiveStock <= 9)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "Low Stock",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 90,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
