import 'package:flutter/material.dart';

class SearchButton extends StatefulWidget {
  final bool dark;
  final ValueChanged<String> onSearch;

  const SearchButton({super.key, required this.dark, required this.onSearch});

  @override
  State<SearchButton> createState() => _SearchButtonState();
}

class _SearchButtonState extends State<SearchButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  bool _isExpanded = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 225),
      vsync: this,
    );
    _widthAnimation = Tween<double>(
      begin: 50,
      end: 300,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    if (_isExpanded) {
      if (_textController.text.isEmpty) {
        _controller.reverse();
        setState(() => _isExpanded = false);
      } else {
        _textController.clear();
        widget.onSearch("");
      }
    } else {
      _controller.forward();
      setState(() => _isExpanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final primaryColor = colors.primary;
    final dark = widget.dark;
    final backgroundColor = dark ? primaryColor : theme.cardColor;
    final contentColor = dark ? colors.onPrimary : primaryColor;

    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          height: 50,
          margin: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: _isExpanded
              ? Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: TextField(
                          controller: _textController,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: contentColor,
                          ),
                          cursorColor: contentColor,
                          onChanged: widget.onSearch,
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(
                              color: dark
                                  ? colors.onPrimary
                                  : colors.onSurfaceVariant,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.close, color: contentColor, size: 20),
                      onPressed: _toggleSearch,
                    ),
                    const SizedBox(width: 10),
                  ],
                )
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleSearch,
                    borderRadius: BorderRadius.circular(25),
                    child: Center(
                      child: Icon(Icons.search, color: contentColor),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearch;

  const SearchBarWidget({super.key, required this.onSearch});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final primaryColor = colors.primary;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              style: Theme.of(context).textTheme.bodyMedium,
              onChanged: widget.onSearch,
              decoration: const InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty) ...[
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.close, color: primaryColor, size: 20),
              onPressed: () {
                _controller.clear();
                widget.onSearch("");
              },
            ),
          ],
        ],
      ),
    );
  }
}
