import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';
import '../models/reward_item_model.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import 'auth_provider.dart';

//Service

final cartServiceProvider = Provider<CartService>((ref) => CartService());

//Stream: all carts for the current user

final myCartsProvider = StreamProvider<List<CartItemModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final service = ref.watch(cartServiceProvider);
  return service.getCartsByUser(user.uid);
});

//Enriched cart (with product details for display)

final enrichedCartProvider =
    FutureProvider.family<CartItemModel, CartItemModel>((ref, cart) async {
  final service = ref.read(cartServiceProvider);
  return service.enrichCart(cart);
});

//Notifier: add to cart

class CartNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Add quantity of product to the current user's cart for organizerId.
  Future<void> addToCart({
    required String organizerId,
    required ProductModel product,
    required int quantity,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(cartServiceProvider).addToCart(
            userId: user.uid,
            organizerId: organizerId,
            product: product,
            quantity: quantity,
          );
    });
  }

  /// Update quantity for a specific product inside a cart.
  Future<void> updateQuantity({
    required String cartId,
    required String productId,
    required int newQuantity,
    required Map<String, int> currentProducts,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(cartServiceProvider).updateProductQuantity(
            cartId: cartId,
            productId: productId,
            newQuantity: newQuantity,
            currentProducts: currentProducts,
          );
    });
  }

  /// Remove a product from a cart.
  Future<void> removeProduct({
    required String cartId,
    required String productId,
    required Map<String, int> currentProducts,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(cartServiceProvider).removeProduct(
            cartId: cartId,
            productId: productId,
            currentProducts: currentProducts,
          );
    });
  }

  /// Delete an entire cart.
  Future<void> deleteCart(String cartId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(cartServiceProvider).deleteCart(cartId);
    });
  }

  /// Clear all carts for the current user.
  Future<void> clearAll() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(cartServiceProvider).clearAllCarts(user.uid);
    });
  }

  /// Checkout a single cart: place an order, then delete the cart.
  Future<void> checkout(CartItemModel cart) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final orderService = OrderService();
      // Calculate total including 10 pesos service fee.
      // We explicitly pass the total with fee to ensure database consistency.
      final totalWithFee = cart.points + 10.0;
      
      await orderService.placeOrder(
        OrganizerId: cart.organizerId,
        userId: user.uid,
        orders: cart.products,
        points: totalWithFee,
      );

      // Delete the cart after the order is placed
      await ref.read(cartServiceProvider).deleteCart(cart.id);
    });
  }

  /// Buy now: place an order immediately without adding to cart.
  Future<void> buyNow({
    required String organizerId,
    required ProductModel product,
    required int quantity,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final orderService = OrderService();
      // Calculate total including 10 pesos service fee.
      final totalWithFee = (product.points * quantity) + 10.0;
      
      await orderService.placeOrder(
        OrganizerId: organizerId,
        userId: user.uid,
        orders: {product.id: quantity},
        points: totalWithFee,
      );
    });
  }
}

final cartNotifierProvider = AsyncNotifierProvider<CartNotifier, void>(
  CartNotifier.new,
);
