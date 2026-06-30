import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusgo/widgets/top_bar.dart';
import '../../models/product_model.dart';
import '../../models/enums.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final dynamic product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final initialProduct = widget.product as ProductModel;
    
    // Watch the product stream to get real-time stock updates
    final productsAsync = ref.watch(vendorProductsProvider(initialProduct.businessId));
    
    return productsAsync.when(
      loading: () => _buildScaffold(context, initialProduct),
      error: (e, _) => _buildScaffold(context, initialProduct),
      data: (products) {
        final product = products.firstWhere(
          (p) => p.id == initialProduct.id,
          orElse: () => initialProduct,
        );
        
        // Calculate effective stock if it's a promo, discount, or bundle
        final effectiveStock = product.calculateEffectiveStock(products);
        
        // Adjust quantity if it exceeds current stock
        if (quantity > effectiveStock && effectiveStock > 0) {
          quantity = effectiveStock;
        } else if (effectiveStock == 0) {
          quantity = 0;
        }

        return _buildScaffold(context, product, effectiveStock: effectiveStock);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, ProductModel product, {int? effectiveStock}) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    
    final displayStock = effectiveStock ?? product.stock;
    final isOutOfStock = displayStock <= 0;
    final isLowStock = displayStock > 0 && displayStock <= 9;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: TopBar(title: "Product", dark: true, showBack: true),
      body: Column(
        children: [
          /// PRODUCT IMAGE
          Stack(
            children: [
              ColorFiltered(
                colorFilter: isOutOfStock
                    ? const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0, 0, 0, 1, 0,
                      ])
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
                child: Container(
                  height: 260,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: product.imageUrl != null
                      ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              ),
              if (isOutOfStock)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: Text(
                        "UNAVAILABLE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// NAME & STOCK STATUS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(product.name, style: textTheme.titleLarge),
                        ),
                        if (isOutOfStock)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Out of Stock",
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isLowStock
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isLowStock
                                  ? "Only $displayStock left!"
                                  : "$displayStock in stock",
                              style: TextStyle(
                                color: isLowStock
                                    ? Colors.orange.shade900
                                    : Colors.green.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    /// PRICE
                    Row(
                      children: [
                        Text(
                          "₱${product.price.toStringAsFixed(2)}",
                          style: textTheme.titleMedium?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product.originalPrice != null && product.originalPrice! > product.price) ...[
                          const SizedBox(width: 10),
                          Text(
                            "₱${product.originalPrice!.toStringAsFixed(2)}",
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (product.discountPercentage != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "-${product.discountPercentage!.toStringAsFixed(0)}%",
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),

                    if (product.categories.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: product.categories.map((cat) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cat,
                            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                          ),
                        )).toList(),
                      ),
                    ],

                    const SizedBox(height: 20),

                    /// DESCRIPTION
                    Text("Description", style: textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Text(
                      product.description.isNotEmpty
                          ? product.description
                          : "No description available.",
                      style: textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 20),

                    /// ADDITIONAL INFO
                    if (product.sku.isNotEmpty || product.supplier.isNotEmpty) ...[
                      Text("Product Details", style: textTheme.titleSmall),
                      const SizedBox(height: 10),
                      if (product.sku.isNotEmpty)
                        _detailRow("SKU", product.sku),
                      if (product.supplier.isNotEmpty)
                        _detailRow("Supplier", product.supplier),
                      const SizedBox(height: 20),
                    ],

                    /// QUANTITY SELECTOR
                    if (!isOutOfStock)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Quantity", style: textTheme.titleMedium),
                              Text(
                                "Max: $displayStock",
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _qtyButton(Icons.remove, () {
                                if (quantity > 1) {
                                  setState(() => quantity--);
                                }
                              }),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  "$quantity",
                                  style: textTheme.bodyLarge,
                                ),
                              ),
                              _qtyButton(Icons.add, () {
                                if (quantity < displayStock) {
                                  setState(() => quantity++);
                                }
                              }),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() => quantity = displayStock);
                                },
                                child: const Text("MAX"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),

          /// BUY BUTTONS
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isOutOfStock
                          ? null
                          : () async {
                              await ref
                                  .read(cartNotifierProvider.notifier)
                                  .addToCart(
                                    businessId: product.businessId,
                                    product: product,
                                    quantity: quantity,
                                  );

                              if (context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${product.name} x$quantity added to cart!',
                                    ),
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOutOfStock
                            ? Colors.grey
                            : primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Add to Cart",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isOutOfStock
                          ? null
                          : () async {
                              // Show confirmation dialog
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Buy Now'),
                                  content: Text(
                                    'Place order for ${product.name} x$quantity '
                                    'totalling ₱${(product.price * quantity).toStringAsFixed(2)}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('Confirm'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed != true) return;
                              
                              try {
                                await ref.read(cartNotifierProvider.notifier).buyNow(
                                  businessId: product.businessId,
                                  product: product,
                                  quantity: quantity,
                                );
                                
                                if (context.mounted) {
                                  final user = ref.read(currentUserProvider);
                                  final route = user?.role != Role.customer ? '/business-dashboard' : '/dashboard';
                                  
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    route,
                                    (route) => false,
                                    arguments: {'backToProcessing': true},
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOutOfStock
                            ? Colors.grey
                            : Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Buy Now",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
