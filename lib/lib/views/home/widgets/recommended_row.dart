import 'package:flutter/material.dart';

class RecommendedRow extends StatelessWidget {
  const RecommendedRow({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.shopping_bag, color: primaryColor, size: 35),
          );
        },
      ),
    );
  }
}
