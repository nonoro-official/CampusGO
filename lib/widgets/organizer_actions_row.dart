import 'package:flutter/material.dart';

class VendorActionsRow extends StatelessWidget {
  const VendorActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    final actions = [
      {'icon': Icons.add_box, 'label': 'Add Product', 'route': '/inventory'},
      {
        'icon': Icons.receipt_long,
        'label': 'View Orders',
        'route': '/incoming-orders',
      },
      {
        'icon': Icons.inventory,
        'label': 'Manage Listings',
        'route': '/listings',
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        actions.length,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index != actions.length - 1 ? 12 : 0,
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, actions[index]['route'] as String);
              },
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      actions[index]['icon'] as IconData,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      actions[index]['label'] as String,
                      style: textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
