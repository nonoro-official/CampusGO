import 'dart:io';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/reward_item_model.dart';
import '../../../models/enums.dart';
import '../../../providers/product_provider.dart';
import '../../../widgets/modal.dart';
import '../../../widgets/product_image_picker.dart';

String _generateAutoSku() {
  final random = Random();
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(
    8,
  );
  final randomStr = List.generate(3, (index) => random.nextInt(10)).join();
  return "SKU-$timestamp$randomStr";
}

void showListingModal({
  required BuildContext context,
  required WidgetRef ref,
  required String organizerId,
  ProductModel? product,
}) {
  ModalContainer.show(
    context: context,
    child: _ListingModal(organizerId: organizerId, product: product),
  );
}

class _ListingModal extends ConsumerStatefulWidget {
  final String organizerId;
  final ProductModel? product;

  const _ListingModal({required this.organizerId, this.product});

  @override
  ConsumerState<_ListingModal> createState() => _ListingModalState();
}

class _ListingModalState extends ConsumerState<_ListingModal> {
  late final TextEditingController nameController;
  late final TextEditingController priceController;
  late final TextEditingController salePriceController;
  late final TextEditingController descriptionController;
  late final TextEditingController stockController;
  late final TextEditingController skuController;
  late final TextEditingController categoryController;
  late final TextEditingController supplierController;
  late final TextEditingController promoQuantityController;
  late final TextEditingController discountPercentController;

  late ListingType selectedType;
  late bool isAvailable;
  String? selectedBaseProductId;
  late List<String> selectedBundleItems;
  File? selectedImage;
  bool isLoading = false;
  List<String> categories = [];
  List<String> localSuggestions = [];

  @override
  void initState() {
    super.initState();
    final product = widget.product;

    nameController = TextEditingController(text: product?.name);

    // If it's a discounted item, priceController stores the Original Price
    final initialBasePrice = (product?.originalPrice != null)
        ? product!.originalPrice
        : (product?.price ?? 0.0);

    priceController = TextEditingController(text: initialBasePrice.toString());
    salePriceController = TextEditingController(
      text: product?.price.toString() ?? "0.0",
    );
    descriptionController = TextEditingController(text: product?.description);
    stockController = TextEditingController(
      text: product?.stock.toString() ?? "0",
    );
    skuController = TextEditingController(
      text: product?.sku ?? (product == null ? _generateAutoSku() : ''),
    );
    categoryController = TextEditingController();
    supplierController = TextEditingController(text: product?.supplier);

    promoQuantityController = TextEditingController(
      text: product?.promoQuantity?.toString() ?? "1",
    );
    discountPercentController = TextEditingController(
      text: product?.discountPercentage?.toString() ?? "0",
    );

    selectedType = product?.type ?? ListingType.bundle;
    isAvailable = product?.isAvailable ?? true;
    selectedBaseProductId = product?.linkedProductId;
    selectedBundleItems = product?.bundleItems ?? [];
    categories = product != null ? List<String>.from(product.categories) : [];
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    salePriceController.dispose();
    descriptionController.dispose();
    stockController.dispose();
    skuController.dispose();
    categoryController.dispose();
    supplierController.dispose();
    promoQuantityController.dispose();
    discountPercentController.dispose();
    super.dispose();
  }

  void _syncSalePrice() {
    final p = double.tryParse(priceController.text) ?? 0.0;
    final d = double.tryParse(discountPercentController.text) ?? 0.0;
    final s = p * (1 - (d / 100));
    salePriceController.text = s.toStringAsFixed(2);
  }

  void _syncDiscountPercent() {
    final s = double.tryParse(salePriceController.text) ?? 0.0;
    final p = double.tryParse(priceController.text) ?? 0.0;
    if (p > 0) {
      final d = (1 - (s / p)) * 100;
      discountPercentController.text = d.toStringAsFixed(0);
    }
  }

  void _toggleCategory(String cat) {
    setState(() {
      if (categories.contains(cat)) {
        categories.remove(cat);
      } else {
        categories.add(cat);
      }
    });
  }

  void _addManualCategory() {
    final val = categoryController.text.trim();
    if (val.isNotEmpty) {
      setState(() {
        if (!localSuggestions.contains(val)) {
          localSuggestions.add(val);
        }
        if (!categories.contains(val)) {
          categories.add(val);
        }
        categoryController.clear();
      });
    }
  }

  Future<void> _handleDeleteSuggestion(String cat, bool isExisting) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category Suggestion'),
        content: Text(
          isExisting
              ? 'This will remove "$cat" from ALL your products in the database. Continue?'
              : 'Remove "$cat" from your temporary suggestions?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (isExisting) {
        try {
          await ref
              .read(productServiceProvider)
              .removeCategoryFromOrganizer(widget.organizerId, cat);
          if (mounted) {
            setState(() {
              categories.remove(cat);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Category "$cat" removed from all products'),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        }
      } else {
        setState(() {
          localSuggestions.remove(cat);
          categories.remove(cat);
        });
      }
    }
  }

  void _updateBundleSuppliers(List<ProductModel> baseProducts) {
    final uniqueSuppliers = <String>{};
    for (var itemName in selectedBundleItems) {
      final item = baseProducts.firstWhereOrNull((bp) => bp.name == itemName);
      if (item != null && item.supplier.isNotEmpty) {
        uniqueSuppliers.add(item.supplier);
      }
    }
    supplierController.text = uniqueSuppliers.join(', ');
  }

  void updateStockDisplay(List<ProductModel> baseProducts) {
    final bool isBaseItem =
        widget.product != null &&
        (widget.product!.type == ListingType.regular ||
            (widget.product!.type == ListingType.discount &&
                widget.product!.linkedProductId == null));

    if (isBaseItem || selectedType == ListingType.regular) return;

    if (selectedType == ListingType.promo ||
        selectedType == ListingType.discount) {
      final base = baseProducts.firstWhereOrNull(
        (p) => p.id == selectedBaseProductId,
      );
      if (base == null) {
        stockController.text = "0";
      } else {
        if (selectedType == ListingType.promo) {
          final qty = int.tryParse(promoQuantityController.text) ?? 1;
          stockController.text = (qty > 0 ? base.stock ~/ qty : 0).toString();
        } else {
          stockController.text = base.stock.toString();
        }
      }
    } else if (selectedType == ListingType.bundle) {
      if (selectedBundleItems.isEmpty) {
        stockController.text = "0";
      } else {
        int minStock = -1;
        for (var name in selectedBundleItems) {
          final item = baseProducts.firstWhereOrNull((p) => p.name == name);
          final s = item?.stock ?? 0;
          if (minStock == -1 || s < minStock) minStock = s;
        }
        stockController.text = (minStock == -1 ? 0 : minStock).toString();
      }
    }
  }

  Future<void> _handleSave() async {
    final name = nameController.text.trim();
    final originalPriceStr = priceController.text.trim();
    final originalPriceVal = double.tryParse(originalPriceStr) ?? 0.0;
    final sellingPriceVal =
        double.tryParse(salePriceController.text.trim()) ?? originalPriceVal;
    final discountPct = double.tryParse(discountPercentController.text) ?? 0.0;

    final stock = int.tryParse(stockController.text) ?? 0;
    final description = descriptionController.text.trim();
    final sku = skuController.text.trim();
    final supplier = supplierController.text.trim();

    _addManualCategory();

    if (name.isEmpty ||
        originalPriceStr.isEmpty ||
        sku.isEmpty ||
        categories.isEmpty ||
        supplier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields (*) including at least one category',
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final productService = ref.read(productServiceProvider);
      String? imageUrl = widget.product?.imageUrl;

      if (selectedImage != null) {
        imageUrl = await productService.uploadProductImage(selectedImage!);
      }

      bool isDiscountable =
          selectedType == ListingType.discount ||
          selectedType == ListingType.promo ||
          selectedType == ListingType.bundle;

      double finalPrice = isDiscountable ? sellingPriceVal : originalPriceVal;
      double? savedOriginalPrice;
      double? savedDiscountPercentage;

      if (isDiscountable) {
        if (discountPct > 0 || sellingPriceVal < originalPriceVal) {
          savedOriginalPrice = originalPriceVal;
          savedDiscountPercentage = discountPct > 0
              ? discountPct
              : ((1 - (sellingPriceVal / originalPriceVal)) * 100);
        }
      }

      int? promoQty = int.tryParse(promoQuantityController.text);

      if (widget.product == null) {
        await productService.createVendorProduct(
          organizerId: widget.organizerId,
          name: name,
          description: description,
          price: finalPrice,
          stock: stock,
          type: selectedType,
          isAvailable: isAvailable,
          imageUrl: imageUrl,
          bundleItems: selectedType == ListingType.bundle
              ? selectedBundleItems
              : null,
          promoQuantity: promoQty,
          originalPrice: savedOriginalPrice,
          discountPercentage: savedDiscountPercentage,
          linkedProductId: selectedBaseProductId,
          sku: sku,
          categories: categories,
          supplier: supplier,
        );
      } else {
        await productService.updateVendorProduct(
          productId: widget.product!.id,
          OrganizerId: widget.organizerId,
          name: name,
          description: description,
          price: finalPrice,
          stock: stock,
          type: selectedType,
          isAvailable: isAvailable,
          imageUrl: imageUrl,
          bundleItems: selectedType == ListingType.bundle
              ? selectedBundleItems
              : null,
          promoQuantity: promoQty,
          originalPrice: savedOriginalPrice,
          discountPercentage: savedDiscountPercentage,
          linkedProductId: selectedBaseProductId,
          sku: sku,
          categories: categories,
          supplier: supplier,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    final productsAsync = ref.watch(vendorProductsProvider(widget.organizerId));
    final allProducts = productsAsync.value ?? [];

    final baseProducts = allProducts
        .where(
          (p) =>
              p.type == ListingType.regular ||
              (p.type == ListingType.discount && p.linkedProductId == null),
        )
        .toList();

    final currentBaseProduct = baseProducts.firstWhereOrNull(
      (p) => p.id == selectedBaseProductId,
    );

    final bool isBaseItem =
        widget.product != null &&
        (widget.product!.type == ListingType.regular ||
            (widget.product!.type == ListingType.discount &&
                widget.product!.linkedProductId == null));

    bool isDiscountable =
        selectedType == ListingType.discount ||
        selectedType == ListingType.promo ||
        selectedType == ListingType.bundle;

    final existingCategories = allProducts
        .expand((p) => p.categories)
        .toSet()
        .toList();
    existingCategories.sort();

    final allDisplayCategories = {
      ...existingCategories,
      ...localSuggestions,
    }.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product == null
                ? "New Special Listing"
                : (isBaseItem ? "Manage Listing" : "Edit Listing"),
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 20),

          ProductImagePicker(
            initialImageUrl: widget.product?.imageUrl,
            onImagePicked: (file) => setState(() => selectedImage = file),
          ),
          const SizedBox(height: 20),

          if (isBaseItem)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Discount Listing", style: textTheme.titleSmall),
                      Text(
                        selectedType == ListingType.discount
                            ? "Current: Discounted"
                            : "Current: Regular",
                        style: textTheme.bodySmall?.copyWith(
                          color: selectedType == ListingType.discount
                              ? Colors.red
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: selectedType == ListingType.discount,
                    activeThumbColor: Colors.red,
                    onChanged: (val) {
                      setState(() {
                        selectedType = val
                            ? ListingType.discount
                            : ListingType.regular;
                        if (!val) {
                          discountPercentController.text = "0";
                          salePriceController.text = priceController.text;
                        }
                      });
                    },
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<ListingType>(
              initialValue: selectedType == ListingType.regular
                  ? ListingType.bundle
                  : selectedType,
              decoration: const InputDecoration(
                labelText: 'Listing Type',
                border: OutlineInputBorder(),
              ),
              items: ListingType.values
                  .where((t) {
                    if (t == ListingType.regular) return false;
                    if (widget.product == null && t == ListingType.discount) {
                      return false;
                    }
                    return true;
                  })
                  .map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.toName),
                    );
                  })
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedType = val;
                    if (widget.product == null) {
                      nameController.clear();
                      priceController.clear();
                      salePriceController.clear();
                      descriptionController.clear();
                      skuController.text = _generateAutoSku();
                      categoryController.clear();
                      supplierController.clear();
                      selectedBundleItems = [];
                      selectedBaseProductId = null;
                      discountPercentController.text = "0";
                      categories = [];
                      localSuggestions = [];
                    }
                    updateStockDisplay(baseProducts);
                  });
                }
              },
            ),
          const SizedBox(height: 15),

          if (isDiscountable) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: discountPercentController,
                    decoration: const InputDecoration(
                      labelText: 'Discount %',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setState(() {
                        _syncSalePrice();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: salePriceController,
                    decoration: const InputDecoration(
                      labelText: 'Sale Price (₱)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _syncDiscountPercent();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],

          if (!isBaseItem &&
              (selectedType == ListingType.promo ||
                  (selectedType == ListingType.discount &&
                      widget.product == null))) ...[
            DropdownButtonFormField<ProductModel>(
              initialValue: currentBaseProduct,
              decoration: const InputDecoration(
                labelText: 'Select Base Product',
                border: OutlineInputBorder(),
              ),
              hint: const Text("Choose an existing product"),
              items: baseProducts.map((p) {
                return DropdownMenuItem(value: p, child: Text(p.name));
              }).toList(),
              onChanged: (p) {
                if (p != null) {
                  setState(() {
                    selectedBaseProductId = p.id;
                    nameController.text = p.name;
                    descriptionController.text = p.description;

                    if (selectedType == ListingType.promo) {
                      final qty =
                          int.tryParse(promoQuantityController.text) ?? 1;
                      priceController.text =
                          ((p.originalPrice ?? p.price) * qty).toString();
                    } else {
                      priceController.text = (p.originalPrice ?? p.price)
                          .toString();
                    }

                    _syncSalePrice();
                    skuController.text = p.sku;
                    categories = List<String>.from(p.categories);
                    supplierController.text = p.supplier;
                    updateStockDisplay(baseProducts);
                  });
                }
              },
            ),
            const SizedBox(height: 15),
          ],

          if (selectedType == ListingType.bundle) ...[
            Text("Select Bundle Items", style: textTheme.bodySmall),
            const SizedBox(height: 5),
            Wrap(
              spacing: 8,
              children: baseProducts.map((p) {
                final isSelected = selectedBundleItems.contains(p.name);
                return FilterChip(
                  label: Text(p.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedBundleItems.add(p.name);
                        // Add categories from the added item to bundle categories if they don't exist
                        for (var cat in p.categories) {
                          if (!categories.contains(cat)) {
                            categories.add(cat);
                          }
                        }
                      } else {
                        selectedBundleItems.remove(p.name);
                      }

                      if (selectedBundleItems.isNotEmpty) {
                        nameController.text = selectedBundleItems.join(' + ');

                        double total = 0;
                        for (var itemName in selectedBundleItems) {
                          final item = baseProducts.firstWhereOrNull(
                            (bp) => bp.name == itemName,
                          );
                          if (item != null) {
                            total += (item.originalPrice ?? item.price);
                          }
                        }
                        priceController.text = total.toString();
                        _syncSalePrice();
                      }
                      _updateBundleSuppliers(baseProducts);
                      updateStockDisplay(baseProducts);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 15),
          ],

          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Listing Name (Display) *',
            ),
            enabled: !isBaseItem,
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: isDiscountable
                        ? 'Original Price (₱) *'
                        : 'Price (₱) *',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (isDiscountable) {
                        _syncSalePrice();
                      }
                    });
                  },
                  enabled: !isBaseItem,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextField(
                  controller: stockController,
                  decoration: InputDecoration(
                    labelText: selectedType == ListingType.regular || isBaseItem
                        ? 'Stock'
                        : 'Effective Stock',
                    hintText: 'Calculated from base',
                  ),
                  keyboardType: TextInputType.number,
                  enabled: isBaseItem,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),
          TextField(
            controller: skuController,
            decoration: InputDecoration(
              labelText: 'SKU *',
              suffixIcon: !isBaseItem
                  ? IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () => setState(
                        () => skuController.text = _generateAutoSku(),
                      ),
                    )
                  : null,
            ),
            enabled: !isBaseItem,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: categoryController,
            decoration: InputDecoration(
              labelText: 'Add New Category',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _addManualCategory,
              ),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
            onSubmitted: (_) => _addManualCategory(),
            enabled:
                !isBaseItem ||
                (isBaseItem && selectedType == ListingType.discount),
          ),
          if (allDisplayCategories.isNotEmpty &&
              (!isBaseItem ||
                  (isBaseItem && selectedType == ListingType.discount))) ...[
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Select Categories (Long press to delete suggestion):",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: allDisplayCategories.map((cat) {
                  final isSelected = categories.contains(cat);
                  final isExisting = existingCategories.contains(cat);
                  return GestureDetector(
                    onLongPress: () => _handleDeleteSuggestion(cat, isExisting),
                    child: FilterChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => _toggleCategory(cat),
                      selectedColor: Theme.of(context).primaryColor,
                      checkmarkColor: Colors.white,
                      showCheckmark: true,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 15),
          TextField(
            controller: supplierController,
            decoration: const InputDecoration(
              labelText: 'Supplier * (Automatic)',
            ),
            enabled: !isBaseItem,
          ),

          if (selectedType == ListingType.promo) ...[
            const SizedBox(height: 15),
            TextField(
              controller: promoQuantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity for Promo *',
                hintText: 'e.g., 2',
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                setState(() {
                  final qty = int.tryParse(val) ?? 1;
                  final base = baseProducts.firstWhereOrNull(
                    (p) => p.id == selectedBaseProductId,
                  );
                  if (base != null) {
                    priceController.text =
                        ((base.originalPrice ?? base.price) * qty).toString();
                    _syncSalePrice();
                  }
                  updateStockDisplay(baseProducts);
                });
              },
            ),
          ],

          const SizedBox(height: 15),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: 'Listing Description'),
            maxLines: 2,
            enabled: !isBaseItem,
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleSave,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.product == null
                          ? 'Create Listing'
                          : 'Save Changes',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
