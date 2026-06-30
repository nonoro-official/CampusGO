import 'package:flutter/material.dart';
import 'package:campusgo/services/message_service.dart';
import 'package:campusgo/services/business_service.dart';
import '../chat_page.dart';
import '../../../widgets/top_bar.dart';
import '../../../widgets/modal.dart';

class CartItemScreen extends StatelessWidget {
  final String accountType;
  final Map<String, dynamic> order;

  const CartItemScreen({
    super.key,
    required this.order,
    required this.accountType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final primaryColor = theme.primaryColor;

    final List<Map<String, dynamic>> items = order["items"];
    // ignore: unused_local_variable
    final int subtotal = order["subtotal"];
    final int total =
        order["subtotal"] + 10; // Adding service fee for demonstration
    int qty = order["total_qty"];

    final status = order["status"];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "Total: ₱$total",
                style: textTheme.titleMedium?.copyWith(color: primaryColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (status == "Completed") {
                  Navigator.pushNamed(
                    context,
                    "/shops",
                    // (route) => false,
                  );
                } else if (status == "Processing") {
                  final businessId = order["businessId"];
                  if (businessId != null) {
                    final business = await BusinessService().getBusiness(
                      businessId,
                    );
                    if (business != null) {
                      await MessageService().initiateContact(business.ownerId);
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              receiverName: business.businessName,
                              receiverID: business.ownerId,
                              receiverImageUrl: business.imageUrl,
                            ),
                          ),
                        );
                      }
                    }
                  }
                } else if (status == "To Payment") {
                  ModalContainer.popup(
                    context: context,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 40),
                            Text(
                              "Confirm Payment",
                              style: textTheme.titleLarge?.copyWith(
                                color: primaryColor,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const Divider(),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.3,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  item["name"].toString(),
                                  style: textTheme.bodyMedium,
                                ),
                                trailing: Text(
                                  "x${item["quantity"]}",
                                  style: textTheme.bodyMedium,
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Amount:",
                                style: textTheme.titleSmall,
                              ),
                              Text(
                                "₱$total",
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                accountType == "Customer"
                                    ? '/dashboard'
                                    : '/business-dashboard',
                                (route) => false,
                                arguments: {
                                  'accountType': accountType,
                                  'backToProcessing': true,
                                  'openTab': 2,
                                },
                              );
                            },
                            child: const Text("Confirm & Pay"),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: status == "Completed"
                  ? const Text("Buy Again")
                  : status == "To Payment"
                  ? const Text("Proceed to Payment")
                  : const Text("Contact Seller"),
            ),
          ],
        ),
      ),

      appBar: TopBar(title: 'Order Summary', showBack: true, dark: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Product Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.shopping_bag,
                      size: 30,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order["order_id"], style: textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                          "₱$total",
                          style: textTheme.titleSmall?.copyWith(
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text("Quantity: $qty", style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = items[index];
                return OrderSummaryItems(item: item);
              },
            ),

            const SizedBox(height: 10),

            // Order Details Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildRow(context, "Subtotal", "₱$subtotal"),
                  const SizedBox(height: 10),
                  _buildRow(context, "Service Fee", "₱10"),
                  const SizedBox(height: 10),
                  _buildRow(context, "Campus Pickup", "Free"),
                  const Divider(height: 25),
                  _buildRow(context, "Total Payment", "₱$total", isTotal: true),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Payment Method Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: primaryColor),
                  const SizedBox(width: 10),
                  Text("Cash on Pickup", style: textTheme.titleSmall),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String title,
    String value, {
    bool isTotal = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: isTotal ? textTheme.titleSmall : textTheme.bodyMedium,
        ),
        Text(
          value,
          style: (isTotal ? textTheme.titleSmall : textTheme.bodyMedium)
              ?.copyWith(
                fontWeight: FontWeight.bold,
                color: isTotal ? primaryColor : Colors.black87,
              ),
        ),
      ],
    );
  }
}

class OrderSummaryItems extends StatelessWidget {
  final Map<String, dynamic> item;

  const OrderSummaryItems({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item["name"].toString(), style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Text("Qty: ${item["quantity"]}", style: textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  "₱${item["total"]}",
                  style: textTheme.titleSmall?.copyWith(color: primaryColor),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.shopping_bag, color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
