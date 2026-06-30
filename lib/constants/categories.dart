import 'package:flutter/material.dart';

class CategoryData {
  final String label;
  final IconData icon;

  const CategoryData({required this.label, required this.icon});
}

const List<CategoryData> shopCategories = [
  CategoryData(label: 'Food & Drinks', icon: Icons.fastfood),
  CategoryData(label: 'Clothing', icon: Icons.checkroom),
  CategoryData(label: 'Accessories', icon: Icons.watch),
  CategoryData(label: 'Art & Crafts', icon: Icons.brush),
  CategoryData(label: 'Merch & Collectibles', icon: Icons.catching_pokemon),
  CategoryData(label: 'Toys & Plushies', icon: Icons.toys),
  CategoryData(label: 'Books & Prints', icon: Icons.menu_book),
  CategoryData(label: 'School Supplies', icon: Icons.school),
  CategoryData(label: 'Gadgets & Tech', icon: Icons.devices),
  CategoryData(label: 'Plants & Decor', icon: Icons.local_florist),
  CategoryData(label: 'Services', icon: Icons.build),
  CategoryData(label: 'Others', icon: Icons.more_horiz),
];
