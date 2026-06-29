import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

/// One-time backfill function to add timestamp-based orderNumbers to existing orders
/// Add this to your app initialization and call once, then remove.
/// Example: await backfillOrderNumbers();
Future<void> backfillOrderNumbers() async {
  debugPrint('Starting backfill of orderNumbers...');

  final db = FirebaseFirestore.instance;
  final ordersCollection = db.collection('orders');

  try {
    final snapshot = await ordersCollection.get();
    int updatedCount = 0;
    int skippedCount = 0;

    // Process in batches of 500 (Firestore batch limit)
    final batch = db.batch();
    int batchCount = 0;
    const batchSize = 500;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      // Skip if already has orderNumber
      if (data.containsKey('orderNumber') && data['orderNumber'] != null) {
        debugPrint('✓ Order ${doc.id} already has orderNumber: ${data['orderNumber']}');
        skippedCount++;
        continue;
      }

      // Get timestamp
      final timestamp = data['timestamp'];
      if (timestamp == null) {
        debugPrint('✗ Order ${doc.id} has no timestamp, skipping');
        skippedCount++;
        continue;
      }

      // Convert Firestore Timestamp to DateTime
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else {
        debugPrint('✗ Order ${doc.id} has invalid timestamp format, skipping');
        skippedCount++;
        continue;
      }

      // Generate orderNumber: ORD-YYYYMMDD-HHMMSS
      final orderNumber =
          'ORD-${dateTime.year}${dateTime.month.toString().padLeft(2, '0')}'
          '${dateTime.day.toString().padLeft(2, '0')}-'
          '${dateTime.hour.toString().padLeft(2, '0')}'
          '${dateTime.minute.toString().padLeft(2, '0')}'
          '${dateTime.second.toString().padLeft(2, '0')}';

      // Add to batch
      batch.update(ordersCollection.doc(doc.id), {'orderNumber': orderNumber});
      batchCount++;
      updatedCount++;

      debugPrint('→ Batch queued: Order ${doc.id} ← $orderNumber');

      // Commit batch if it reaches the size limit
      if (batchCount >= batchSize) {
        await batch.commit();
        debugPrint('✓ Committed batch of $batchCount updates');
        batchCount = 0;
      }
    }

    // Commit remaining batch
    if (batchCount > 0) {
      await batch.commit();
      debugPrint('✓ Committed final batch of $batchCount updates');
    }

    debugPrint('\n=== Backfill Complete ===');
    debugPrint('Updated: $updatedCount orders');
    debugPrint('Skipped: $skippedCount orders');
    debugPrint('Total: ${snapshot.docs.length} orders processed');
  } catch (e) {
    debugPrint('Error during backfill: $e');
    rethrow;
  }
}

