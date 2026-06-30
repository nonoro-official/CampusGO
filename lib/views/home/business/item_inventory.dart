import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/modal.dart';
import '../../../widgets/product_image_picker.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../services/product_service.dart';
import '../../../models/product_model.dart';
import '../../../models/enums.dart';

void addItemInventory(BuildContext context) {
  ModalContainer.show(context: context, child: const _AddItemModal());
}

class _AddItemModal extends ConsumerStatefulWidget {
  const _AddItemModal();

  @override
  ConsumerState<_AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends ConsumerState<_AddItemModal> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;
  late final TextEditingController stockController;
  late final TextEditingController skuController;
  late final TextEditingController categoryController;
  late final TextEditingController supplierController;
  bool isLoading = false;
  File? selectedImage;
  List<String> categories = [];
  List<String> localSuggestions = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    priceController = TextEditingController();
    stockController = TextEditingController();
    skuController = TextEditingController(text: _generateAutoSku());
    categoryController = TextEditingController();
    supplierController = TextEditingController();
  }

  String _generateAutoSku() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(8);
    final randomStr = List.generate(3, (index) => random.nextInt(10)).join();
    return "SKU-$timestamp$randomStr";
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
    skuController.dispose();
    categoryController.dispose();
    supplierController.dispose();
    super.dispose();
  }

  void _addCategory() {
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

  void _toggleCategory(String cat) {
    setState(() {
      if (categories.contains(cat)) {
        categories.remove(cat);
      } else {
        categories.add(cat);
      }
    });
  }

  Future<void> _handleDeleteSuggestion(
    String businessId,
    String cat,
    bool isExisting,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category Suggestion'),
        content: Text(
          isExisting
              ? 'This will remove "$cat" from ALL your products. Continue?'
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
              .removeCategoryFromBusiness(businessId, cat);
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final businessId = user?.businessId ?? '';
    final existingCategoriesAsync = ref.watch(
      vendorCategoriesProvider(businessId),
    );
    final existingCategories = existingCategoriesAsync.value ?? [];

    final allDisplayCategories = {
      ...existingCategories,
      ...localSuggestions,
    }.toList()..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Add Item",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 20),
            ProductImagePicker(
              onImagePicked: (file) => setState(() => selectedImage = file),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                border: OutlineInputBorder(),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price (₱) *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: skuController,
              decoration: const InputDecoration(
                labelText: 'SKU *',
                border: OutlineInputBorder(),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: categoryController,
              decoration: InputDecoration(
                labelText: 'Add New Category *',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addCategory,
                ),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              onSubmitted: (_) => _addCategory(),
            ),
            if (allDisplayCategories.isNotEmpty) ...[
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Select Categories * (Long press to delete suggestion):",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
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
                      onLongPress: () =>
                          _handleDeleteSuggestion(businessId, cat, isExisting),
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
                labelText: 'Supplier *',
                border: OutlineInputBorder(),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Item Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleAddItem,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddItem() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final priceStr = priceController.text.trim();
    final stock = int.tryParse(stockController.text) ?? 0;
    final sku = skuController.text.trim();
    final supplier = supplierController.text.trim();

    _addCategory();

    if (name.isEmpty ||
        priceStr.isEmpty ||
        sku.isEmpty ||
        categories.isEmpty ||
        supplier.isEmpty) {
      _showError(
        'Please fill all required fields (*) including at least one category',
      );
      return;
    }

    final price = double.tryParse(priceStr) ?? 0.0;
    if (price <= 0) {
      _showError('Price must be greater than 0');
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user?.businessId == null) {
        _showError('Business ID not found');
        return;
      }

      final productService = ref.read(productServiceProvider);
      String? imageUrl;

      if (selectedImage != null) {
        imageUrl = await productService.uploadProductImage(selectedImage!);
      }

      await productService.createVendorProduct(
        businessId: user!.businessId!,
        name: name,
        description: description,
        price: price,
        stock: stock,
        imageUrl: imageUrl,
        sku: sku,
        categories: categories,
        supplier: supplier,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully!')),
        );
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}

void editItemInventory(BuildContext context, ProductModel product) {
  ModalContainer.show(
    context: context,
    child: _EditItemModal(product: product),
  );
}

Future<void> deleteItemInventory(
  BuildContext context,
  ProductModel product,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Product'),
      content: Text(
        'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      final productService = ProductService();
      await productService.deleteVendorProduct(product.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting product: $e')));
      }
    }
  }
}

class _EditItemModal extends ConsumerStatefulWidget {
  final ProductModel product;

  const _EditItemModal({required this.product});

  @override
  ConsumerState<_EditItemModal> createState() => _EditItemModalState();
}

class _EditItemModalState extends ConsumerState<_EditItemModal> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;
  late final TextEditingController stockController;
  late final TextEditingController skuController;
  late final TextEditingController categoryController;
  late final TextEditingController supplierController;
  bool isLoading = false;
  File? selectedImage;
  late List<String> categories;
  List<String> localSuggestions = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product.name);
    descriptionController = TextEditingController(
      text: widget.product.description,
    );

    final basePrice = widget.product.originalPrice ?? widget.product.price;
    priceController = TextEditingController(text: basePrice.toString());
    stockController = TextEditingController(
      text: widget.product.stock.toString()  ?? "0",
    );

    skuController = TextEditingController(text: widget.product.sku);
    categoryController = TextEditingController();
    supplierController = TextEditingController(text: widget.product.supplier);
    categories = List<String>.from(widget.product.categories);
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
    skuController.dispose();
    categoryController.dispose();
    supplierController.dispose();
    super.dispose();
  }

  void _addCategory() {
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

  void _toggleCategory(String cat) {
    setState(() {
      if (categories.contains(cat)) {
        categories.remove(cat);
      } else {
        categories.add(cat);
      }
    });
  }

  Future<void> _handleDeleteSuggestion(
    String businessId,
    String cat,
    bool isExisting,
  ) async {
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
              .removeCategoryFromBusiness(businessId, cat);
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

  Future<void> _saveChanges() async {
    final name = nameController.text.trim();
    final priceStr = priceController.text.trim();
    final stock = int.tryParse(stockController.text) ?? 0;
    final sku = skuController.text.trim();
    final supplier = supplierController.text.trim();

    _addCategory();

    if (name.isEmpty ||
        priceStr.isEmpty ||
        sku.isEmpty ||
        categories.isEmpty ||
        supplier.isEmpty) {
      _showError('Please fill in required fields');
      return;
    }

    final basePrice = double.tryParse(priceStr);
    if (basePrice == null || basePrice <= 0) {
      _showError('Please enter a valid price');
      return;
    }

    setState(() => isLoading = true);

    try {
      final productService = ref.read(productServiceProvider);

      String? imageUrl = widget.product.imageUrl;
      if (selectedImage != null) {
        imageUrl = await productService.uploadProductImage(selectedImage!);
      }

      double finalPrice = basePrice;
      double? originalPrice;
      if (widget.product.type == ListingType.discount &&
          widget.product.discountPercentage != null) {
        originalPrice = basePrice;
        finalPrice =
            basePrice * (1 - (widget.product.discountPercentage! / 100));
      }

      await productService.updateVendorProduct(
        productId: widget.product.id,
        businessId: widget.product.businessId,
        name: name,
        description: descriptionController.text.trim(),
        price: finalPrice,
        stock: stock,
        originalPrice: originalPrice,
        discountPercentage: widget.product.discountPercentage,
        imageUrl: imageUrl,
        sku: sku,
        categories: categories,
        supplier: supplier,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
      }
    } catch (e) {
      _showError('Error updating product: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final isDiscounted = widget.product.type == ListingType.discount;
    final businessId = widget.product.businessId;
    final existingCategoriesAsync = ref.watch(
      vendorCategoriesProvider(businessId),
    );
    final existingCategories = existingCategoriesAsync.value ?? [];

    final allDisplayCategories = {
      ...existingCategories,
      ...localSuggestions,
    }.toList()..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Edit Item",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 20),
            ProductImagePicker(
              initialImageUrl: widget.product.imageUrl,
              onImagePicked: (file) => setState(() => selectedImage = file),
            ),
            const SizedBox(height: 20),

            if (isDiscounted)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "This item is currently discounted (${widget.product.discountPercentage?.toStringAsFixed(0)}%). You can manage the discount in the Listings tab.",
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                border: OutlineInputBorder(),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: isDiscounted
                          ? 'Base Price (₱) *'
                          : 'Price (₱) *',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: skuController,
              decoration: const InputDecoration(
                labelText: 'SKU *',
                border: OutlineInputBorder(),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: categoryController,
              decoration: InputDecoration(
                labelText: 'Add New Category',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addCategory,
                ),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              onSubmitted: (_) => _addCategory(),
            ),
            if (allDisplayCategories.isNotEmpty) ...[
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Select Categories (Long press to delete suggestion):",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
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
                      onLongPress: () =>
                          _handleDeleteSuggestion(businessId, cat, isExisting),
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
                labelText: 'Supplier *',
                border: OutlineInputBorder(),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Item Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveChanges,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
