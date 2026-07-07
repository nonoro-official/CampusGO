import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
            return RewardSelectionCard(product: products[index]);
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

  const RewardSelectionCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => _showQRGenerationDialog(context, product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black12)],
        ),
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
                        // Assuming product.price represents the points to give
                        "${product.price.toStringAsFixed(0)} Points",
                        style: textTheme.bodyMedium?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.qr_code, color: primaryColor),
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
    );
  }

  void _showQRGenerationDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) {
        return QRGenerationModal(product: product);
      },
    );
  }
}

// ----------------------------------------------------------------------
// State Modal for handling Quantity -> QR Generation
// ----------------------------------------------------------------------
class QRGenerationModal extends StatefulWidget {
  final ProductModel product;

  const QRGenerationModal({super.key, required this.product});

  @override
  State<QRGenerationModal> createState() => _QRGenerationModalState();
}

class _QRGenerationModalState extends State<QRGenerationModal> {
  int quantity = 1;
  String? generatedQrData;

  void _generateQR() {
    // Treat price as points per item
    final int totalPoints = (widget.product.price * quantity).toInt();

    // Generate a unique ID so each QR is "one-time use"
    final String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();

    // Create the exact JSON format expected by Part 1's scanner
    final Map<String, dynamic> qrPayload = {
      "app": "CampusGO",
      "type": "reward",
      "points": totalPoints,
      "qrId": uniqueId,
    };

    setState(() {
      generatedQrData = jsonEncode(qrPayload);
    });

    /* SECURITY NOTE: To make this strictly one-time use securely,
      you should save 'uniqueId' to Firebase here. When the user
      scans it in Part 1, the app checks if the uniqueId exists in
      Firebase, awards the points, and then deletes it.
    */
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Reward: ${widget.product.name}",
          style: textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text("Quantity Redeemable:", style: textTheme.bodyLarge),
        const SizedBox(height: 10),

        // Quantity Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: quantity > 1 ? primaryColor : Colors.grey,
              iconSize: 32,
              onPressed: () {
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
              color: primaryColor,
              iconSize: 32,
              onPressed: () {
                setState(() => quantity++);
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
            onPressed: _generateQR,
            child: const Text("Generate QR Code"),
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

        // The generated QR Code
        Container(
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
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
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
    );
  }
}