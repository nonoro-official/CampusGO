import 'package:flutter/material.dart';

class FilterWidget extends StatefulWidget {
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String?> onChanged;

  const FilterWidget({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          clipBehavior: Clip.antiAlias,
          height: 45,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: _isMenuOpen
                ? const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  )
                : BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            onOpened: () {
              setState(() {
                _isMenuOpen = true;
              });
            },
            onCanceled: () {
              setState(() {
                _isMenuOpen = false;
              });
            },
            onSelected: (value) {
              setState(() {
                _isMenuOpen = false;
              });
              widget.onChanged(value);
            },
            initialValue: widget.selectedValue,
            offset: const Offset(-20,
                45), // Height of the container, subtract horizontal padding
            elevation: 8,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxWidth: constraints.maxWidth,
              maxHeight: 300,
            ),
            itemBuilder: (BuildContext context) {
              return widget.options.map((String value) {
                return PopupMenuItem<String>(
                  value: value,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ),
                );
              }).toList();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.selectedValue,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
