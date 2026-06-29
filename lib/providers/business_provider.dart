import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/models/business_model.dart';
import '../lib/models/enums.dart';
import '../lib/services/business_service.dart';
import 'auth_provider.dart';

final businessServiceProvider = Provider<BusinessService>(
  (ref) => BusinessService(),
);

final allVendorsProvider = StreamProvider<List<BusinessModel>>((ref) {
  final businessService = ref.watch(businessServiceProvider);
  return businessService.getAllBusinesses();
});

final myBusinessProvider = StreamProvider<BusinessModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.businessId == null) return Stream.value(null);

  final businessService = ref.watch(businessServiceProvider);
  return businessService.getBusinessStream(user.businessId!);
});

// Stream of a single business by id (useful for showing names in lists)
final businessProvider = StreamProvider.family<BusinessModel?, String>((
  ref,
  businessId,
) {
  final service = ref.watch(businessServiceProvider);
  return service.getBusinessStream(businessId);
});

class VendorStatusNotifier extends Notifier<ActiveStatus> {
  @override
  ActiveStatus build() {
    // Listens to the business stream. If DB changes, UI updates automatically.
    final business = ref.watch(myBusinessProvider).value;
    return business?.activeStatus ?? ActiveStatus.closed;
  }

  Future<void> updateStatus(ActiveStatus status, {String? eta}) async {
    // Get current business ID from the stream provider
    final business = ref.read(myBusinessProvider).value;
    if (business == null) return;

    final businessService = ref.read(businessServiceProvider);
    await businessService.updateStatus(business.id, status, eta: eta);
  }

  Future<void> uploadBusinessPhoto(File file) async {
    final business = ref.read(myBusinessProvider).value;
    if (business == null) return;
    await ref
        .read(businessServiceProvider)
        .updateBusinessImage(business.id, file);
  }
}

final vendorStatusProvider =
    NotifierProvider<VendorStatusNotifier, ActiveStatus>(
      VendorStatusNotifier.new,
    );
