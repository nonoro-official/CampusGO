import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/organizer_model.dart';
import '../models/enums.dart';
import '../services/organizer_service.dart';
import 'auth_provider.dart';

final organizerServiceProvider = Provider<OrganizerService>(
  (ref) => OrganizerService(),
);

final allOrganizersProvider = StreamProvider<List<OrganizerModel>>((ref) {
  final organizerService = ref.watch(organizerServiceProvider);
  return organizerService.getAllOrganizers();
});

final myOrganizerProvider = StreamProvider<OrganizerModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.organizerId == null) return Stream.value(null);

  final organizerService = ref.watch(organizerServiceProvider);
  return organizerService.getOrganizerStream(user.organizerId!);
});

// Stream of a single organizer by id (useful for showing names in lists)
final organizerProvider = StreamProvider.family<OrganizerModel?, String>((
  ref,
  organizerId,
) {
  final service = ref.watch(organizerServiceProvider);
  return service.getOrganizerStream(organizerId);
});

class OrganizerStatusNotifier extends Notifier<ActiveStatus> {
  @override
  ActiveStatus build() {
    // Listens to the organizer stream. If DB changes, UI updates automatically.
    final organizer = ref.watch(myOrganizerProvider).value;
    return organizer?.activeStatus ?? ActiveStatus.closed;
  }

  Future<void> updateStatus(ActiveStatus status, {String? eta}) async {
    // Get current organizer ID from the stream provider
    final organizer = ref.read(myOrganizerProvider).value;
    if (organizer == null) return;

    final organizerService = ref.read(organizerServiceProvider);
    await organizerService.updateStatus(organizer.id, status, eta: eta);
  }

  Future<void> uploadOrganizerPhoto(File file) async {
    final organizer = ref.read(myOrganizerProvider).value;
    if (organizer == null) return;
    await ref
        .read(organizerServiceProvider)
        .updateOrganizerImage(organizer.id, file);
  }
}

final organizerStatusProvider =
    NotifierProvider<OrganizerStatusNotifier, ActiveStatus>(
      OrganizerStatusNotifier.new,
    );
