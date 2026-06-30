import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';
import '../models/reward_item_model.dart';

class CartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //References

  CollectionReference<Map<String, dynamic>> get _carts =>
      _db.collection('carts');

  //Stream: all cart docs for a user

  Stream<List<CartItemModel>> getCartsByUser(String userId) {
    return _carts
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CartItemModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  //Stream: single cart doc

  Stream<CartItemModel?> getCartStream(String cartId) {
    return _carts.doc(cartId).snapshots().map(
          (doc) => doc.exists
              ? CartItemModel.fromMap(doc.data()!, doc.id)
              : null,
        );
  }

  //Find existing cart for user + Organizer

  Future<CartItemModel?> findCart(String userId, String organizerId) async {
    final snap = await _carts
        .where('userId', isEqualTo: userId)
        .where('organizerId', isEqualTo: organizerId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return CartItemModel.fromMap(doc.data(), doc.id);
  }

  //Add / update a product in the cart

  /// Adds [quantity] of [product] to the user's cart for [OrganizerId].
  /// Creates the cart document if it doesn't exist yet.
  Future<void> addToCart({
    required String userId,
    required String organizerId,
    required ProductModel product,
    required int quantity,
  }) async {
    // 1. Fetch latest stock to ensure we don't exceed it
    final productDoc = await _db.collection('products').doc(product.id).get();
    if (!productDoc.exists) throw Exception('Product not found');
    
    final latestStock = (productDoc.data()!['stock'] ?? 0) is int
        ? productDoc.data()!['stock']
        : int.tryParse(productDoc.data()!['stock']?.toString() ?? '0') ?? 0;

    // Look for an existing cart for this user + Organizer
    var cart = await findCart(userId, organizerId);

    if (cart == null) {
      if (quantity > latestStock) {
        throw Exception('Only $latestStock items left in stock.');
      }

      // Create a new cart doc
      final products = {product.id: quantity};
      final price = product.price * quantity;

      await _carts.add({
        'userId': userId,
        'organizerId': organizerId,
        'products': products,
        'price': price,
      });
    } else {
      // Update existing cart
      final updatedProducts = Map<String, int>.from(cart.products);
      final currentInCart = updatedProducts[product.id] ?? 0;
      final newTotalQuantity = currentInCart + quantity;

      if (newTotalQuantity > latestStock) {
        throw Exception('Only $latestStock items left in stock. You already have $currentInCart in your cart.');
      }

      updatedProducts[product.id] = newTotalQuantity;

      // Recalculate total price
      final newPrice = await _recalculatePrice(updatedProducts);

      await _carts.doc(cart.id).update({
        'products': updatedProducts,
        'price': newPrice,
      });
    }
  }

  //Update quantity for a specific product

  Future<void> updateProductQuantity({
    required String cartId,
    required String productId,
    required int newQuantity,
    required Map<String, int> currentProducts,
  }) async {
    final updated = Map<String, int>.from(currentProducts);

    if (newQuantity <= 0) {
      updated.remove(productId);
    } else {
      // Check stock before updating
      final productDoc = await _db.collection('products').doc(productId).get();
      if (productDoc.exists) {
        final stock = (productDoc.data()!['stock'] ?? 0) is int
            ? productDoc.data()!['stock']
            : int.tryParse(productDoc.data()!['stock']?.toString() ?? '0') ?? 0;
        
        if (newQuantity > stock) {
          throw Exception('Only $stock items left in stock.');
        }
      }
      updated[productId] = newQuantity;
    }

    //If no products left, delete the cart doc
    if (updated.isEmpty) {
      await _carts.doc(cartId).delete();
      return;
    }

    final newPrice = await _recalculatePrice(updated);

    await _carts.doc(cartId).update({
      'products': updated,
      'price': newPrice,
    });
  }

  //Remove a product from the cart

  Future<void> removeProduct({
    required String cartId,
    required String productId,
    required Map<String, int> currentProducts,
  }) async {
    return updateProductQuantity(
      cartId: cartId,
      productId: productId,
      newQuantity: 0,
      currentProducts: currentProducts,
    );
  }

  //Delete entire cart

  Future<void> deleteCart(String cartId) async {
    await _carts.doc(cartId).delete();
  }

  //Clear all carts for a user

  Future<void> clearAllCarts(String userId) async {
    final snap = await _carts.where('userId', isEqualTo: userId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  //Enrich a cart with product names / images / prices

  Future<CartItemModel> enrichCart(CartItemModel cart) async {
    final List<CartLineItem> lineItems = [];

    for (final entry in cart.products.entries) {
      final productId = entry.key;
      final qty = entry.value;

      final doc = await _db.collection('products').doc(productId).get();
      if (doc.exists) {
        final product = ProductModel.fromMap(doc.data()!, doc.id);
        lineItems.add(CartLineItem(
          productId: productId,
          name: product.name,
          imageUrl: product.imageUrl,
          quantity: qty,
          unitPrice: product.price,
        ));
      }
    }

    return cart.copyWithLineItems(lineItems);
  }

  //Helpers

  /// Fetches current product prices and recalculates the total.
  Future<double> _recalculatePrice(Map<String, int> products) async {
    double total = 0;
    for (final entry in products.entries) {
      final doc = await _db.collection('products').doc(entry.key).get();
      if (doc.exists) {
        final price = (doc.data()!['price'] ?? 0).toDouble();
        total += price * entry.value;
      }
    }
    return total;
  }
}
