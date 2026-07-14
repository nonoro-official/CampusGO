import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RewardImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final bool isAvailable;

  const RewardImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 16.0,
    this.fit = BoxFit.cover,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? colors.surfaceContainerHighest
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? colors.outlineVariant
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: isAvailable
                  ? const ColorFilter.mode(
                      Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix([
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ]),
              child: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: fit,
                      placeholder: (context, url) => Container(
                        color: theme.brightness == Brightness.dark
                            ? colors.surfaceContainerHighest
                            : Colors.grey.shade100,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildPlaceholder(context),
                    )
                  : _buildPlaceholder(context),
            ),
            if (!isAvailable)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: Text(
                    "UNAVAILABLE",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: (height != null && height! < 100) ? 24 : 40,
            color: colors.onSurfaceVariant,
          ),
          if (height == null || height! >= 100) ...[
            const SizedBox(height: 8),
            Text(
              "No Image",
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
