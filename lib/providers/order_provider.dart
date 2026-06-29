import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/models/order_model.dart';
import '../lib/services/order_service.dart';
import 'auth_provider.dart';
import '../lib/providers/business_provider.dart';

// ─── Service ─────────────────────────────────────────────────────────────────

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

// ─── Vendor: stream all orders for my business ───────────────────────────────

final businessOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final business = ref.watch(myBusinessProvider).value;
  if (business == null) return Stream.value([]);

  final service = ref.watch(orderServiceProvider);
  return service.getOrdersByBusiness(business.id);
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

// ─── Enriched single order (with product details) ────────────────────────────

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

