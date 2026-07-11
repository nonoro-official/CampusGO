import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for secure validation ledger
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import '../../../widgets/top_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../models/reward_item_model.dart';
import '../../../models/enums.dart';

class QRGeneratorScreen extends ConsumerWidget {
  const QRGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const TopBar(
        title: 'Generate Reward QR',
        showBack: true,
        center: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  "Select Product to Reward",
                  style: textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Display the list of products/rewards
            if (user?.organizerId != null)
              Expanded(
                child: RewardProductList(organizerId: user!.organizerId!),
              )
            else
              const Expanded(
                child: Center(child: Text('No Organizer found')),
              ),
          ],
        ),
      ),
    );
  }
}

class RewardProductList extends ConsumerWidget {
  final String organizerId;

  const RewardProductList({super.key, required this.organizerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(organizerProductsProvider(organizerId));

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(child: Text("No products found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return RewardSelectionCard(
              product: products[index],
              allProducts: products,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class RewardSelectionCard extends StatelessWidget {
  final ProductModel product;
  final List<ProductModel> allProducts;

  const RewardSelectionCard({
    super.key,
    required this.product,
    required this.allProducts,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    final int stock = product.calculateEffectiveStock(allProducts);

    return GestureDetector(
      onTap: stock > 0 ? () => _showQRGenerationDialog(context, product, allProducts) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: stock > 0 ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(22),
          boxShadow: stock > 0 ? const [BoxShadow(blurRadius: 12, color: Colors.black12)] : null,
        ),
        child: Opacity(
          opacity: stock > 0 ? 1.0 : 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          "${product.price.toStringAsFixed(0)} Points • $stock in stock",
                          style: textTheme.bodyMedium?.copyWith(
                            color: stock > 0 ? primaryColor : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: stock > 0 ? primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.qr_code, 
                      color: stock > 0 ? primaryColor : Colors.grey
                    ),
                  ),
                ],
              ),
              if (product.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  product.description,
                  style: textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  void _showQRGenerationDialog(BuildContext context, ProductModel product, List<ProductModel> allProducts) {
    showDialog(
      context: context,
      builder: (context) {
        return QRGenerationModal(product: product, allProducts: allProducts);
      },
    );
  }
}

// ----------------------------------------------------------------------
// State Modal for handling Quantity -> QR Generation
// ----------------------------------------------------------------------
class QRGenerationModal extends StatefulWidget {
  final ProductModel product;
  final List<ProductModel> allProducts;

  const QRGenerationModal({
    super.key,
    required this.product,
    required this.allProducts,
  });

  @override
  State<QRGenerationModal> createState() => _QRGenerationModalState();
}

class _QRGenerationModalState extends State<QRGenerationModal> {
  final GlobalKey _qrKey = GlobalKey();
  int quantity = 1;
  String? generatedQrData;
  bool _isLoading = false; // Prevents double submission crashes
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // No need to initialize quantity here as it defaults to 1
  }

  Future<void> _saveQRCode() async {
    setState(() => _isSaving = true);
    try {
      // 1. Ensure we have gallery access
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        hasAccess = await Gal.requestAccess();
      }

      if (!hasAccess) {
        throw Exception("Gallery access denied.");
      }

      final RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await file.writeAsBytes(pngBytes);

        await Gal.putImage(file.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("QR Code saved to Gallery!"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save QR: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Changed to async to safely push the transaction token to Firestore
  void _generateQR() async {
    setState(() {
      _isLoading = true;
    });

    final int totalPoints = (widget.product.price * quantity).toInt();

    // Create a highly distinct identifier token combining Product ID + Current Epoch Timestamp
    final String uniqueId = "${widget.product.id}_${DateTime.now().millisecondsSinceEpoch}";

    try {
      // 1. Log the token signature in the decentralized db cloud ledger
      await FirebaseFirestore.instance.collection('rewards_ledger').doc(uniqueId).set({
        'points': totalPoints,
        'status': 'unused', // Key parameter checked by Part 1 scanner
        'createdAt': FieldValue.serverTimestamp(),
        'productId': widget.product.id,
        'productName': widget.product.name,
        'organizerId': widget.product.organizerId,
        'quantity': quantity,
      });

      // 2. Map payload keys identical to the scanner validation parameters
      final Map<String, dynamic> qrPayload = {
        "app": "CampusGO",
        "type": "reward",
        "points": totalPoints,
        "qrId": uniqueId,
      };

      if (mounted) {
        setState(() {
          generatedQrData = jsonEncode(qrPayload);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to secure validation token: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    final totalPoints = (widget.product.price * quantity).toInt();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: generatedQrData == null
            ? _buildConfigurationView(textTheme, primaryColor, totalPoints)
            : _buildQRView(textTheme, primaryColor, totalPoints),
      ),
    );
  }

  Widget _buildConfigurationView(TextTheme textTheme, Color primaryColor, int totalPoints) {
    final int maxStock = widget.product.calculateEffectiveStock(widget.allProducts);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Reward: ${widget.product.name}",
          style: textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Available Stock: $maxStock",
          style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        Text("Quantity Redeemable:", style: textTheme.bodyLarge),
        const SizedBox(height: 10),

        // Quantity Selector Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: quantity > 1 && !_isLoading ? primaryColor : Colors.grey,
              iconSize: 32,
              onPressed: _isLoading
                  ? null
                  : () {
                if (quantity > 1) setState(() => quantity--);
              },
            ),
            const SizedBox(width: 20),
            Text(
              "$quantity",
              style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: quantity < maxStock && !_isLoading ? primaryColor : Colors.grey,
              iconSize: 32,
              onPressed: _isLoading
                  ? null
                  : () {
                if (quantity < maxStock) {
                  setState(() => quantity++);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        Text(
          "Total Reward: $totalPoints Pts",
          style: textTheme.titleMedium?.copyWith(color: Colors.green.shade700),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _generateQR,
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text("Generate QR Code"),
          ),
        ),
      ],
    );
  }

  Widget _buildQRView(TextTheme textTheme, Color primaryColor, int totalPoints) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Customer Scan Here",
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          "$totalPoints Pts for $quantity x ${widget.product.name}",
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Render dynamic payload text parameters out to image format
        RepaintBoundary(
          key: _qrKey,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: QrImageView(
              data: generatedQrData!,
              version: QrVersions.auto,
              size: 200.0,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveQRCode,
                icon: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download),
                label: const Text("Save Image"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                },
                child: const Text("Done"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}