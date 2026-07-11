import 'dart:convert'; // Required for JSON decoding
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../models/enums.dart';

class MockQRScannerPage extends ConsumerStatefulWidget {
  const MockQRScannerPage({super.key});

  @override
  ConsumerState<MockQRScannerPage> createState() => _MockQRScannerPageState();
}

class _MockQRScannerPageState extends ConsumerState<MockQRScannerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Controller for the live camera
  final MobileScannerController _scannerController = MobileScannerController();

  // Prevents multiple scans of the same code in a split second
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Keeps the nice laser animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose(); // Always dispose of the camera
    super.dispose();
  }

  // --- Secure Core Scanning Logic ---
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final BarcodeCapture? capture = await _scannerController.analyzeImage(image.path);
      if (capture != null && capture.barcodes.isNotEmpty) {
        _onDetect(capture);
      } else {
        _showError("No QR code found in the selected image.");
      }
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return; // Block further reads while processing

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null) return;

    setState(() {
      _isProcessing = true; // Lock the scanner state UI
    });

    try {
      // 1. Decode the QR code JSON string payload
      final Map<String, dynamic> qrData = jsonDecode(rawValue);

      // 2. Structural Guard Check: Is it a CampusGO reward token?
      if (qrData['app'] == 'CampusGO' && qrData['type'] == 'reward') {
        final int pointsToAward = qrData['points'] ?? 0;
        final String qrId = qrData['qrId'] ?? '';

        if (qrId.isEmpty) {
          _showError("Invalid token structure missing identifier.");
          return;
        }

        // --- NEW: FIRESTORE LEDGER ANTI-EXPLOIT HANDSHAKE ---
        final ledgerRef = FirebaseFirestore.instance.collection('rewards_ledger').doc(qrId);
        final ledgerDoc = await ledgerRef.get();

        // Security Guard A: Does this QR code even exist in our system ledger?
        if (!ledgerDoc.exists) {
          _showError("Invalid or unregistered QR code.");
          return;
        }

        final String status = ledgerDoc.data()?['status'] ?? 'used';

        // Security Guard B: Has this code been scanned before?
        if (status == 'used') {
          _showError("🛑 This QR code has already been redeemed!");
          return;
        }

        final String productName = ledgerDoc.data()?['productName'] ?? 'Reward Item';
        final String? productId = ledgerDoc.data()?['productId'];
        final int quantity = ledgerDoc.data()?['quantity'] ?? 1;

        // --- VALIDATION PASSED: EXECUTE SECURE CLAIM ---

        // Stop the camera view since verification passed cleanly
        await _scannerController.stop();

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // 1. Immediately claim the code in the database ledger to prevent race conditions
          await ledgerRef.update({
            'status': 'used',
            'redeemedBy': user.uid,
            'redeemedAt': FieldValue.serverTimestamp(),
          });

          // 2. Safe increments processing on the user profile record
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {'points': FieldValue.increment(pointsToAward)},
            SetOptions(merge: true),
          );

          // 3. Decrement product stock via transaction
          if (productId != null) {
            try {
              await FirebaseFirestore.instance.runTransaction((transaction) async {
                final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
                final productDoc = await transaction.get(productRef);

                if (productDoc.exists) {
                  final data = productDoc.data()!;
                  final String? linkedId = data['linkedProductId'];
                  final String type = data['type'] ?? 'regular';
                  
                  String targetId = productId;
                  int decrementAmount = quantity;

                  // Promo logic: 1 QR might represent a bundle of items (e.g., "Buy 1 Get 1")
                  if (type == 'promo' && data['promoQuantity'] != null) {
                    decrementAmount = quantity * (data['promoQuantity'] as int);
                  }

                  // Linked logic: Deduct from the source of truth (base product)
                  if (linkedId != null && linkedId.isNotEmpty) {
                     targetId = linkedId;
                  }

                  final targetRef = FirebaseFirestore.instance.collection('products').doc(targetId);
                  
                  // If target is different, we must get it too within the transaction
                  DocumentSnapshot? targetDoc;
                  if (targetId == productId) {
                    targetDoc = productDoc;
                  } else {
                    targetDoc = await transaction.get(targetRef);
                  }

                  if (targetDoc.exists) {
                    final int currentStock = (targetDoc.data() as Map<String, dynamic>)['stock'] ?? 0;
                    transaction.update(targetRef, {
                      'stock': currentStock - decrementAmount,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  }
                }
              });
            } catch (e) {
              debugPrint("Error updating stock in transaction: $e");
            }
          }
        }

        // 4. Complete UX Flow
        if (mounted) {
          _showSuccessDialog(productName, pointsToAward);
        }
      } else {
        // Valid JSON format but wrong app signatures
        _showError("This QR code is not valid for CampusGO rewards.");
      }
    } catch (e) {
      // Catch formatting exceptions (plain text links, wrong structures)
      _showError("Unrecognized QR format.");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );

    // Unlock the scanner after a short delay so they can try reading again
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  void _showSuccessDialog(String productName, int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text("Redemption Successful!", textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "You have successfully redeemed points for:",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              productName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Text(
                "+$points CampusGO Points",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE46A3E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Since this is a tab, we don't pop the screen.
                // We just reset the processing flag and restart camera if needed.
                setState(() {
                  _isProcessing = false;
                });
                _scannerController.start();
              },
              child: const Text("Scan More", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                setState(() {
                  _isProcessing = false;
                });
                _scannerController.start();
              },
              child: const Text("Okay"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanWindowSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text("Scan QR Code",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Live Camera Feed
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // 2. The Dark Overlay with the Transparent Center Cutout
          Center(
            child: Container(
              width: scanWindowSize,
              height: scanWindowSize,
              decoration: BoxDecoration(
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.7),
                      spreadRadius: 2000),
                ],
              ),
            ),
          ),

          // 3. The Scanner UI (Brackets and Laser)
          Center(
            child: SizedBox(
              width: scanWindowSize,
              height: scanWindowSize,
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: _buildCorner(isTop: true, isLeft: true)),
                  Positioned(top: 0, right: 0, child: _buildCorner(isTop: true, isLeft: false)),
                  Positioned(bottom: 0, left: 0, child: _buildCorner(isTop: false, isLeft: true)),
                  Positioned(bottom: 0, right: 0, child: _buildCorner(isTop: false, isLeft: false)),

                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _animationController.value * (scanWindowSize - 4),
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE46A3E),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFFE46A3E).withOpacity(0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2)
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 4. Instructions
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.22,
            left: 0,
            right: 0,
            child: const Column(
              children: [
                Icon(Icons.qr_code_2, color: Colors.white70, size: 40),
                SizedBox(height: 10),
                Text(
                  "Align the QR code within the frame",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // 5. Action Toggles
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMockActionButton(Icons.image, "Gallery", _pickImageFromGallery),
                _buildMockActionButton(Icons.flashlight_on, "Flashlight", () {
                  _scannerController.toggleTorch();
                }),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Color(0xFFE46A3E), width: 4)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Color(0xFFE46A3E), width: 4)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Color(0xFFE46A3E), width: 4)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Color(0xFFE46A3E), width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildMockActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
