import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/search.dart';
import '../widgets/top_bar.dart';
import '../widgets/product_image.dart';
import '../widgets/filter.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../models/business_model.dart';
import '../../../utils/business_utils.dart';
import '../vendor_profile_screen.dart';

class ShopsScreen extends ConsumerStatefulWidget {
  final String? category;

  const ShopsScreen({super.key, this.category});

  @override
  ConsumerState<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends ConsumerState<ShopsScreen> {
  String searchQuery = "";
  String selectedPartner = "All";

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleLabel = widget.category ?? "All Shops";
    final allVendorsAsync = ref.watch(allVendorsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: TopBar(
        title: 'UniMart',
        showBack: true,
        rightIcon: Icons.chat_bubble_outline,
        onRightPressed: () => Navigator.pushNamed(context, "/messages"),
        center: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            /// TITLE
            Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(titleLabel, style: textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text("Browse vendors", style: textTheme.bodySmall),
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// PARTNER FILTER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FilterWidget(
                options: const ["All", "Campus", "Organization", "Student"],
                selectedValue: selectedPartner,
                onChanged: (val) {
                  setState(() {
                    selectedPartner = val ?? "All";
                  });
                },
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: allVendorsAsync.when(
                data: (vendors) {
                  final filteredVendors = vendors.where((v) {
                    final matchesSearch = v.businessName
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase());

                    final matchesCategory =
                        widget.category == null ||
                        v.category == widget.category;

                    final matchesPartner =
                        selectedPartner == "All" ||
                        v.businessPartner.name.toLowerCase() ==
                            selectedPartner.toLowerCase();

                    return matchesSearch &&
                        matchesCategory &&
                        matchesPartner;
                  }).toList();

                  return Stack(
                    children: [
                      filteredVendors.isEmpty
                          ? const Center(child: Text("No vendors found"))
                          : VendorFeed(vendors: filteredVendors),

                      Positioned(
                        bottom: 10,
                        right: 0,
                        child: SearchButton(
                          dark: false,
                          onSearch: (val) =>
                              setState(() => searchQuery = val),
                        ),
                      ),
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    Center(child: Text("Error: $err")),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class VendorFeed extends StatelessWidget {
  final List<BusinessModel> vendors;

  const VendorFeed({super.key, required this.vendors});

  @override
  Widget build(BuildContext context) {
    if (vendors.isEmpty) {
      return const Center(child: Text("No vendors found"));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: vendors.length,
      itemBuilder: (context, index) {
        return VendorCard(vendor: vendors[index]);
      },
    );
  }
}

class VendorCard extends ConsumerWidget {
  final BusinessModel vendor;

  const VendorCard({super.key, required this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    final productsAsync = ref.watch(vendorProductsProvider(vendor.id));
    final isOpen = isBusinessActuallyOpen(vendor.businessHours);
    final hasImage =
        vendor.imageUrl != null && vendor.imageUrl!.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VendorProfileScreen(business: vendor),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      primaryColor.withValues(alpha: 0.1),
                  backgroundImage: hasImage
                      ? NetworkImage(vendor.imageUrl!)
                      : null,
                  child: hasImage
                      ? null
                      : Icon(Icons.store, color: primaryColor),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vendor.businessName,
                          style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        vendor.category ?? 'Vendor',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isOpen ? Colors.greenAccent : Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOpen ? "OPEN" : "CLOSED",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Text(
                    vendor.description ??
                        "No description available.",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  );
                }

                return SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final product = products[index];

                      final effectiveStock =
                          product.calculateEffectiveStock(products);

                      return Stack(
                        children: [
                          ProductImage(
                            imageUrl: product.imageUrl,
                            width: 90,
                            height: 90,
                            borderRadius: 12,
                            isAvailable: effectiveStock > 0,
                          ),
                          if (effectiveStock > 0 &&
                              effectiveStock <= 9)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(
                                      alpha: 0.8),
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "Low Stock",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 90,
                child: Center(
                    child: CircularProgressIndicator()),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}