import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final double points;
  int quantity;

  CartItem({required this.id, required this.name, required this.points, this.quantity = 1});
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  double discountPercentage = 0.0;
  String? appliedVoucherCode;
  int appliedVoucherCost = 0; // NEW: Tracks the point cost of the voucher
  String? currentOrganizerId;

  Map<String, CartItem> get items => _items;
  int get totalItems => _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.values.fold(0, (sum, item) => sum + (item.points * item.quantity));
  double get total => subtotal * (1 - (discountPercentage / 100));

  void addItem(String organizerId, String id, String name, double points) {
    if (currentOrganizerId != null && currentOrganizerId != organizerId) {
      _items.clear();
      discountPercentage = 0.0;
      appliedVoucherCode = null;
      appliedVoucherCost = 0;
    }
    currentOrganizerId = organizerId;

    if (_items.containsKey(id)) {
      _items[id]!.quantity++;
    } else {
      _items[id] = CartItem(id: id, name: name, points: points);
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    if (_items.isEmpty) currentOrganizerId = null;
    notifyListeners();
  }

  // NEW: Now requires the point cost when applying
  void applyVoucher(String code, double percentage, int pointCost) {
    appliedVoucherCode = code;
    discountPercentage = percentage;
    appliedVoucherCost = pointCost;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    discountPercentage = 0.0;
    appliedVoucherCode = null;
    appliedVoucherCost = 0;
    currentOrganizerId = null;
    notifyListeners();
  }
}