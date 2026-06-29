import 'package:flutter/material.dart';

Widget categoryIcon(
  BuildContext context,
  String category,
  IconData icon,
  String label,
) {
  final primaryColor = Theme.of(context).primaryColor;
  final textTheme = Theme.of(context).textTheme;

  return GestureDetector(
    onTap: () => Navigator.pushNamed(
      context,
      '/shops',
      arguments: {'category': category},
    ),
    child: Container(
      width: 70, // Reduced from 85 to bring boxes closer
      margin: const EdgeInsets.only(right: 8), // Reduced from 10
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5),
              ],
            ),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: textTheme.labelMedium,
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    ),
  );
}
