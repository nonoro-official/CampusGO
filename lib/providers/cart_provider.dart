import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  CartItem({required this.id, required this.name, required this.price, this.quantity = 1});
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  double discountPercentage = 0.0;
  String? appliedVoucherCode;

  Map<String, CartItem> get items => _items;

  int get totalItems => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.values.fold(0, (sum, item) => sum + (item.price * item.quantity));

  double get total => subtotal * (1 - (discountPercentage / 100));

  void addItem(String id, String name, double price) {
    if (_items.containsKey(id)) {
      _items[id]!.quantity++;
    } else {
      _items[id] = CartItem(id: id, name: name, price: price);
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void applyVoucher(String code, double percentage) {
    appliedVoucherCode = code;
    discountPercentage = percentage;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    discountPercentage = 0.0;
    appliedVoucherCode = null;
    notifyListeners();
  }
}