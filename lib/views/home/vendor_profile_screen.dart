import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusgo/widgets/top_bar.dart';

import '../../models/business_hours.dart';
import '../../models/business_model.dart';
import '../../models/product_model.dart';
import '../../models/faq_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../utils/business_utils.dart';
import 'leave_review_sheet.dart';
import 'settings/business_edit.dart';
import 'product_detail_screen.dart';
import '../../widgets/product_image.dart';
import 'report_business_sheet.dart';
import '../../models/enums.dart';
import 'chat_page.dart';
import '../../services/message_service.dart';

class VendorProfileScreen extends ConsumerWidget {
  final BusinessModel business;

  const VendorProfileScreen({super.key, required this.business});

  String formatPartner(BusinessPartner partner) {
    return partner.name[0].toUpperCase() + partner.name.substring(1);
  }

  IconData getPartnerIcon(BusinessPartner partner) {
    switch (partner) {
      case BusinessPartner.campus:
        return Icons.school;
      case BusinessPartner.organization:
        return Icons.groups;
      case BusinessPartner.student:
        return Icons.person;
    }
  }

  Color getPartnerColor(BusinessPartner partner) {
    switch (partner) {
      case BusinessPartner.campus:
        return Colors.blue;
      case BusinessPartner.organization:
        return Colors.green;
      case BusinessPartner.student:
        return Colors.orange;
    }
  }

  void _showFAQModal(BuildContext context, List<FAQModel> faqs) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Frequently Asked Questions",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 15),
              if (faqs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("No FAQs available for this business.")),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: faqs.length,
                    itemBuilder: (context, index) {
                      final faq = faqs[index];
                      return ExpansionTile(
                        title: Text(
                          faq.question,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(faq.answer),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the live business data if we have it, otherwise fallback to the passed business object
    final businessStream = ref.watch(businessProvider(business.id));
    final currentBusiness = businessStream.value ?? business;

    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;
    final currentUser = ref.watch(currentUserProvider);
    final isOwnerViewing = currentUser?.uid == currentBusiness.ownerId;

    final reviewsAsync = ref.watch(businessReviewsProvider(currentBusiness.id));
    final isOpen = isBusinessActuallyOpen(currentBusiness.businessHours);
    final hasImage = currentBusiness.imageUrl != null && currentBusiness.imageUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: TopBar(
        title: isOwnerViewing ? "My Business Profile" : "Business Profile",
        showBack: true,
        center: true,
        dashboard: !isOwnerViewing,

        messageReceiverId: currentBusiness.ownerId,
        messageReceiverName: currentBusiness.businessName,
        messageReceiverImage: currentBusiness.imageUrl,

        rightIcon: isOwnerViewing ? Icons.edit : Icons.chat_bubble_outline,
        onRightPressed: isOwnerViewing
            ? () => editBusinessProfile(context, currentBusiness, ref)
            : () async {
                // ✅ ensure chat room exists
                await MessageService().initiateContact(currentBusiness.ownerId);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      receiverName: currentBusiness.businessName,
                      receiverID: currentBusiness.ownerId,
                      receiverImageUrl: currentBusiness.imageUrl,
                    ),
                  ),
                );
              },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// BUSINESS HEADER
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                    backgroundImage: hasImage
                        ? NetworkImage(currentBusiness.imageUrl!)
                        : null,
                    child: hasImage
                        ? null
                        : Icon(Icons.store, size: 40, color: primaryColor),
                  ),
                  const SizedBox(height: 12),

                  /// SHOP NAME
                  Text(currentBusiness.businessName, style: textTheme.titleLarge),
                  const SizedBox(height: 6),

                  // PARTNER TYPE BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: getPartnerColor(currentBusiness.businessPartner)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getPartnerIcon(currentBusiness.businessPartner),
                          size: 16,
                          color: getPartnerColor(currentBusiness.businessPartner),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatPartner(currentBusiness.businessPartner),
                          style: textTheme.bodySmall?.copyWith(
                            color: getPartnerColor(currentBusiness.businessPartner),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// STATUS BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOpen ? Colors.greenAccent : Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOpen ? "OPEN" : "CLOSED",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// DESCRIPTION
                  Text(
                    currentBusiness.description ?? "No description yet",
                    style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  if (!isOwnerViewing)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.flag),
                      label: const Text("Report Business"),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => ReportBusinessSheet(
                            businessId: currentBusiness.id,
                            businessName: currentBusiness.businessName,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// BUSINESS INFO
            _infoTile(
              Icons.access_time,
              "Business Hours",
              _buildHoursDropdown(context, currentBusiness.businessHours),
            ),
            _infoTile(
              Icons.phone,
              "Contact",
              Text(
                currentBusiness.contactNumber.isEmpty ? "-" : currentBusiness.contactNumber,
              ),
            ),
            _infoTile(
              Icons.email,
              "Email",
              Text(currentBusiness.contactEmail.isEmpty ? "-" : currentBusiness.contactEmail),
            ),
            _infoTile(
              Icons.help_outline,
              "FAQ",
              InkWell(
                onTap: () => _showFAQModal(context, currentBusiness.faqs),
                child: Text(
                  "View Frequently Asked Questions",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            /// PRODUCTS SECTION
            _buildProductsSection(currentBusiness.id, context, ref),

            const SizedBox(height: 30),

            /// REVIEWS HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Customer Reviews",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isOwnerViewing)
                  ElevatedButton(
                    child: const Text("Leave Review"),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) =>
                            LeaveReviewSheet(businessId: currentBusiness.id),
                      );
                    },
                  ),
              ],
            ),

            const SizedBox(height: 10),

            /// REVIEWS LIST
            reviewsAsync.when(
              data: (reviews) {
                if (reviews.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(child: Text("No reviews yet")),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person),
                                const SizedBox(width: 8),
                                Text(
                                  review.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(review.comment),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text("Error loading reviews: $e"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildProductsSection(
    String businessId,
    BuildContext context,
    WidgetRef ref,
  ) {
    final productsAsync = ref.watch(vendorProductsProvider(businessId));
    final textTheme = Theme.of(context).textTheme;

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Products', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _productCard(product, context, textTheme, products);
                },
              ),
            ),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Products', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  static Widget _productCard(
    ProductModel product,
    BuildContext context,
    TextTheme textTheme,
    List<ProductModel> allProducts,
  ) {
    final effectiveStock = product.calculateEffectiveStock(allProducts);
    final isOutOfStock = effectiveStock <= 0;
    final isLowStock = effectiveStock > 0 && effectiveStock <= 9;
    final hasDiscount = product.originalPrice != null && product.originalPrice! > product.price;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              color: Colors.black12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            Stack(
              children: [
                ProductImage(
                  imageUrl: product.imageUrl,
                  width: double.infinity,
                  height: 100,
                  borderRadius: 12,
                  isAvailable: !isOutOfStock,
                ),
                if (effectiveStock > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isLowStock ? Colors.orange : Colors.green)
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "$effectiveStock in stock",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            /// DETAILS
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₱${product.price.toStringAsFixed(2)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: hasDiscount ? Colors.red : Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasDiscount && product.discountPercentage != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '-${product.discountPercentage!.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// INFO TILE
  static Widget _infoTile(IconData icon, String title, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildHoursDropdown(
    BuildContext context,
    Map<String, BusinessHours>? businessHours,
  ) {
    if (businessHours == null || businessHours.isEmpty) {
      return const Text("Not set");
    }

    const orderedDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    // Current day of the week
    final now = DateTime.now();
    final currentDay = orderedDays[now.weekday - 1];
    final currentHours = businessHours[currentDay];

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          currentHours != null
              ? "$currentDay: ${currentHours.formatRange(context)}"
              : "Closed today",
          style: const TextStyle(fontSize: 14),
        ),
        tilePadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        children: orderedDays.map((day) {
          final hours = businessHours[day];
          final isToday = day == currentDay;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday
                        ? Theme.of(context).primaryColor
                        : Colors.black,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    right: 60,
                  ), // Increased right padding to 60 to push time more to the left
                  child: Text(
                    hours != null ? hours.formatRange(context) : "Closed",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
