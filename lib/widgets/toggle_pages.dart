import 'package:flutter/material.dart';

class TogglePagesButton extends StatefulWidget {
  final List<Widget> pages;
  final int? initialPage;
  final List<String>? customTitles;

  const TogglePagesButton({
    super.key,
    required this.pages,
    this.customTitles,
    this.initialPage,
  });

  @override
  State<TogglePagesButton> createState() => _TogglePagesButtonState();
}

class _TogglePagesButtonState extends State<TogglePagesButton> {
  int selectedView = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialPage != null) {
      selectedView = widget.initialPage!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final pages = widget.pages;
    final totalPages = pages.length;

    return Stack(
      children: [
        // Content (Map, Shops, etc.)
        Positioned.fill(
          child: IndexedStack(index: selectedView, children: pages),
        ),

        // Toggle Buttons (Floating on top)
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                for (int i = 0; i < totalPages; i++)
                  _toggleButton(
                    widget.customTitles != null
                        ? widget.customTitles![i]
                        : pages[i].toString().split('(').first,
                    i,
                    primaryColor,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleButton(String title, int index, Color primaryColor) {
    final isSelected = selectedView == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedView = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
