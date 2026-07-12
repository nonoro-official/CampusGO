import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/redemption_order_model.dart';
import '../services/order_service.dart';
import 'auth_provider.dart';
import '../providers/organizer_provider.dart';

// ─── Service ─────────────────────────────────────────────────────────────────

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

// ─── Organizer: stream all orders for my Organizer ───────────────────────────────

final organizerOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final organizer = ref.watch(myOrganizerProvider).value;
  if (organizer == null) return Stream.value([]);

  final service = ref.watch(orderServiceProvider);
  return service.getOrdersByOrganizer(organizer.id);
});

// ─── Customer: stream all orders placed by me ────────────────────────────────

final myOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final service = ref.watch(orderServiceProvider);
  return service.getOrdersByUser(user.uid);
});

// ─── Single order stream ─────────────────────────────────────────────────────

final singleOrderProvider =
    StreamProvider.family<OrderModel?, String>((ref, orderId) {
  final service = ref.watch(orderServiceProvider);
  return service.getOrderStream(orderId);
});

// ─── Enriched single order (with reward details) ────────────────────────────

final enrichedOrderProvider =
    FutureProvider.family<OrderModel, OrderModel>((ref, order) async {
  final service = ref.read(orderServiceProvider);
  return service.enrichOrder(order);
});

// ─── Notifier: update order status ───────────────────────────────────────────

class OrderStatusNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(orderServiceProvider).updateOrderStatus(orderId, status);
    });
  }
}

final orderStatusNotifierProvider =
    AsyncNotifierProvider<OrderStatusNotifier, void>(
  OrderStatusNotifier.new,
);

