import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const NavBar({super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    final items = [Icons.home, Icons.map, Icons.store, Icons.shopping_cart];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        items.length,
        (index) => GestureDetector(
          onTap: () => onTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: selectedIndex == index ? primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              items[index],
              color: selectedIndex == index ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
