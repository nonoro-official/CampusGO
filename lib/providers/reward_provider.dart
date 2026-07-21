import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward_item_model.dart';
import '../services/reward_service.dart';

final rewardServiceProvider = Provider<RewardService>(
  (ref) => RewardService(),
);

// Get rewards for a specific organizer (family provider)
final organizerRewardsProvider =
    StreamProvider.family<List<RewardModel>, String>((ref, organizerId) {
      final rewardService = ref.watch(rewardServiceProvider);
      return rewardService.getOrganizerRewardsStream(organizerId);
    });

// Get unique categories for a specific organizer
final organizerCategoriesProvider =
    Provider.family<AsyncValue<List<String>>, String>((ref, organizerId) {
  final rewardsAsync = ref.watch(organizerRewardsProvider(organizerId));
  
  return rewardsAsync.whenData((rewards) {
    final categories = <String>{};
    for (final reward in rewards) {
      categories.addAll(reward.categories);
    }
    final sortedCategories = categories.toList()..sort();
    return sortedCategories;
  });
});
