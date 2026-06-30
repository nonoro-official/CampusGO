import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/organizer_model.dart';
import '../models/enums.dart';
import '../services/organizer_service.dart';
import 'auth_provider.dart';

final OrganizerServiceProvider = Provider<OrganizerService>(
  (ref) => OrganizerService(),
);

final allVendorsProvider = StreamProvider<List<OrganizerModel>>((ref) {
  final OrganizerService = ref.watch(OrganizerServiceProvider);
  return OrganizerService.getAllOrganizers();
});

final myOrganizerProvider = StreamProvider<OrganizerModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.organizerId == null) return Stream.value(null);

  final OrganizerService = ref.watch(OrganizerServiceProvider);
  return OrganizerService.getOrganizerStream(user.organizerId!);
});

// Stream of a single Organizer by id (useful for showing names in lists)
final OrganizerProvider = StreamProvider.family<OrganizerModel?, String>((
  ref,
  organizerId,
) {
  final service = ref.watch(OrganizerServiceProvider);
  return service.getOrganizerStream(organizerId);
});

class VendorStatusNotifier extends Notifier<ActiveStatus> {
  @override
  ActiveStatus build() {
    // Listens to the Organizer stream. If DB changes, UI updates automatically.
    final Organizer = ref.watch(myOrganizerProvider).value;
    return Organizer?.activeStatus ?? ActiveStatus.closed;
  }

  Future<void> updateStatus(ActiveStatus status, {String? eta}) async {
    // Get current Organizer ID from the stream provider
    final Organizer = ref.read(myOrganizerProvider).value;
    if (Organizer == null) return;

    final OrganizerService = ref.read(OrganizerServiceProvider);
    await OrganizerService.updateStatus(Organizer.id, status, eta: eta);
  }

  Future<void> uploadOrganizerPhoto(File file) async {
    final Organizer = ref.read(myOrganizerProvider).value;
    if (Organizer == null) return;
    await ref
        .read(OrganizerServiceProvider)
        .updateOrganizerImage(Organizer.id, file);
  }
}

final vendorStatusProvider =
    NotifierProvider<VendorStatusNotifier, ActiveStatus>(
      VendorStatusNotifier.new,
    );
