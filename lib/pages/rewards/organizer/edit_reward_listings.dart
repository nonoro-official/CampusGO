import 'dart:io';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/reward_item_model.dart';
import '../../../models/enums.dart';
import '../../../providers/reward_provider.dart';
import '../../../widgets/modal.dart';
import '../../../widgets/reward_image_picker.dart';

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
  RewardModel? reward,
}) {
  ModalContainer.show(
    context: context,
    child: _ListingModal(organizerId: organizerId, reward: reward),
  );
}

class _ListingModal extends ConsumerStatefulWidget {
  final String organizerId;
  final RewardModel? reward;

  const _ListingModal({required this.organizerId, this.reward});

  @override
  ConsumerState<_ListingModal> createState() => _ListingModalState();
}

class _ListingModalState extends ConsumerState<_ListingModal> {
  late final TextEditingController nameController;
  late final TextEditingController pointsController;
  late final TextEditingController salePointsController;
  late final TextEditingController descriptionController;
  late final TextEditingController stockController;
  late final TextEditingController skuController;
  late final TextEditingController categoryController;
  late final TextEditingController supplierController;
  late final TextEditingController promoQuantityController;
  late final TextEditingController discountPercentController;

  late ListingType selectedType;
  late bool isAvailable;
  String? selectedBaseRewardId;
  late List<String> selectedBundleItems;
  File? selectedImage;
  bool isLoading = false;
  List<String> categories = [];
  List<String> localSuggestions = [];

  @override
  void initState() {
    super.initState();
    final reward = widget.reward;

    nameController = TextEditingController(text: reward?.name);

    // If it's a discounted item, pointsController stores the Original Points
    final initialBasePoints = (reward?.originalPoints != null)
        ? reward!.originalPoints
        : (reward?.points ?? 0.0);

    pointsController =
        TextEditingController(text: initialBasePoints.toString());
    salePointsController = TextEditingController(
      text: reward?.points.toString() ?? "0.0",
    );
    descriptionController = TextEditingController(text: reward?.description);
    stockController = TextEditingController(
      text: reward?.stock.toString() ?? "0",
    );
    skuController = TextEditingController(
      text: reward?.sku ?? (reward == null ? _generateAutoSku() : ''),
    );
    categoryController = TextEditingController();
    supplierController = TextEditingController(text: reward?.supplier);

    promoQuantityController = TextEditingController(
      text: reward?.promoQuantity?.toString() ?? "1",
    );
    discountPercentController = TextEditingController(
      text: reward?.discountPercentage?.toString() ?? "0",
    );

    selectedType = reward?.type ?? ListingType.bundle;
    isAvailable = reward?.isAvailable ?? true;
    selectedBaseRewardId = reward?.linkedRewardId;
    selectedBundleItems = reward?.bundleItems ?? [];
    categories = reward != null ? List<String>.from(reward.categories) : [];
  }

  @override
  void dispose() {
    nameController.dispose();
    pointsController.dispose();
    salePointsController.dispose();
    descriptionController.dispose();
    stockController.dispose();
    skuController.dispose();
    categoryController.dispose();
    supplierController.dispose();
    promoQuantityController.dispose();
    discountPercentController.dispose();
    super.dispose();
  }

  void _syncSalePoints() {
    final p = int.tryParse(pointsController.text) ?? 0;
    final d = double.tryParse(discountPercentController.text) ?? 0.0;
    final s = (p * (1 - (d / 100))).round();
    salePointsController.text = s.toString();
  }

  void _syncDiscountPercent() {
    final s = int.tryParse(salePointsController.text) ?? 0;
    final p = int.tryParse(pointsController.text) ?? 0;
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
              ? 'This will remove "$cat" from ALL your rewards in the database. Continue?'
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
              .read(rewardServiceProvider)
              .removeCategoryFromOrganizer(widget.organizerId, cat);
          if (mounted) {
            setState(() {
              categories.remove(cat);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Category "$cat" removed from all rewards'),
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

  void _updateBundleSuppliers(List<RewardModel> baseRewards) {
    final uniqueSuppliers = <String>{};
    for (var itemName in selectedBundleItems) {
      final item = baseRewards.firstWhereOrNull((bp) => bp.name == itemName);
      if (item != null && item.supplier.isNotEmpty) {
        uniqueSuppliers.add(item.supplier);
      }
    }
    supplierController.text = uniqueSuppliers.join(', ');
  }

  void updateStockDisplay(List<RewardModel> baseRewards) {
    final bool isBaseItem = widget.reward != null &&
        (widget.reward!.type == ListingType.regular ||
            (widget.reward!.type == ListingType.discount &&
                widget.reward!.linkedRewardId == null));

    if (isBaseItem || selectedType == ListingType.regular) return;

    if (selectedType == ListingType.promo ||
        selectedType == ListingType.discount) {
      final base = baseRewards.firstWhereOrNull(
        (p) => p.id == selectedBaseRewardId,
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
          final item = baseRewards.firstWhereOrNull((p) => p.name == name);
          final s = item?.stock ?? 0;
          if (minStock == -1 || s < minStock) minStock = s;
        }
        stockController.text = (minStock == -1 ? 0 : minStock).toString();
      }
    }
  }

  Future<void> _handleSave() async {
    final name = nameController.text.trim();
    final originalPointsStr = pointsController.text.trim();
    final originalPointsVal = int.tryParse(originalPointsStr) ?? 0;
    final sellingPointsVal =
        int.tryParse(salePointsController.text.trim()) ?? originalPointsVal;
    final discountPct = double.tryParse(discountPercentController.text) ?? 0.0;

    final stock = int.tryParse(stockController.text) ?? 0;
    final description = descriptionController.text.trim();
    final sku = skuController.text.trim();
    final supplier = supplierController.text.trim();

    _addManualCategory();

    if (name.isEmpty ||
        originalPointsStr.isEmpty ||
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
      final rewardService = ref.read(rewardServiceProvider);
      String? imageUrl = widget.reward?.imageUrl;

      if (selectedImage != null) {
        imageUrl = await rewardService.uploadRewardImage(selectedImage!);
      }

      bool isDiscountable = selectedType == ListingType.discount ||
          selectedType == ListingType.promo ||
          selectedType == ListingType.bundle;

      int finalPoints = isDiscountable ? sellingPointsVal : originalPointsVal;
      int? savedOriginalPoints;
      double? savedDiscountPercentage;

      if (isDiscountable) {
        if (discountPct > 0 || sellingPointsVal < originalPointsVal) {
          savedOriginalPoints = originalPointsVal;
          savedDiscountPercentage = discountPct > 0
              ? discountPct
              : ((1 - (sellingPointsVal / originalPointsVal)) * 100);
        }
      }

      int? promoQty = int.tryParse(promoQuantityController.text);

      if (widget.reward == null) {
        await rewardService.createOrganizerReward(
          organizerId: widget.organizerId,
          name: name,
          description: description,
          points: finalPoints,
          stock: stock,
          type: selectedType,
          isAvailable: isAvailable,
          imageUrl: imageUrl,
          bundleItems:
              selectedType == ListingType.bundle ? selectedBundleItems : null,
          promoQuantity: promoQty,
          originalPoints: savedOriginalPoints,
          discountPercentage: savedDiscountPercentage,
          linkedRewardId: selectedBaseRewardId,
          sku: sku,
          categories: categories,
          supplier: supplier,
        );
      } else {
        await rewardService.updateOrganizerReward(
          rewardId: widget.reward!.id,
          organizerId: widget.organizerId,
          name: name,
          description: description,
          points: finalPoints,
          stock: stock,
          type: selectedType,
          isAvailable: isAvailable,
          imageUrl: imageUrl,
          bundleItems:
              selectedType == ListingType.bundle ? selectedBundleItems : null,
          promoQuantity: promoQty,
          originalPoints: savedOriginalPoints,
          discountPercentage: savedDiscountPercentage,
          linkedRewardId: selectedBaseRewardId,
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

    final rewardsAsync =
        ref.watch(organizerRewardsProvider(widget.organizerId));
    final allRewards = rewardsAsync.value ?? [];

    final baseRewards = allRewards
        .where(
          (p) =>
              p.type == ListingType.regular ||
              (p.type == ListingType.discount && p.linkedRewardId == null),
        )
        .toList();

    final currentBaseReward = baseRewards.firstWhereOrNull(
      (p) => p.id == selectedBaseRewardId,
    );

    final bool isBaseItem = widget.reward != null &&
        (widget.reward!.type == ListingType.regular ||
            (widget.reward!.type == ListingType.discount &&
                widget.reward!.linkedRewardId == null));

    bool isDiscountable = selectedType == ListingType.discount ||
        selectedType == ListingType.promo ||
        selectedType == ListingType.bundle;

    final existingCategories =
        allRewards.expand((p) => p.categories).toSet().toList();
    existingCategories.sort();

    final allDisplayCategories = {
      ...existingCategories,
      ...localSuggestions,
    }.toList()
      ..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.reward == null
                ? "New Special Listing"
                : (isBaseItem ? "Manage Listing" : "Edit Listing"),
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          RewardImagePicker(
            initialImageUrl: widget.reward?.imageUrl,
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
                        selectedType =
                            val ? ListingType.discount : ListingType.regular;
                        if (!val) {
                          discountPercentController.text = "0";
                          salePointsController.text = pointsController.text;
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
              items: ListingType.values.where((t) {
                if (t == ListingType.regular) return false;
                if (widget.reward == null && t == ListingType.discount) {
                  return false;
                }
                return true;
              }).map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toName),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedType = val;
                    if (widget.reward == null) {
                      nameController.clear();
                      pointsController.clear();
                      salePointsController.clear();
                      descriptionController.clear();
                      skuController.text = _generateAutoSku();
                      categoryController.clear();
                      supplierController.clear();
                      selectedBundleItems = [];
                      selectedBaseRewardId = null;
                      discountPercentController.text = "0";
                      categories = [];
                      localSuggestions = [];
                    }
                    updateStockDisplay(baseRewards);
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
                        _syncSalePoints();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: salePointsController,
                    decoration: const InputDecoration(
                      labelText: 'Sale Points',
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
                      widget.reward == null))) ...[
            DropdownButtonFormField<RewardModel>(
              initialValue: currentBaseReward,
              decoration: const InputDecoration(
                labelText: 'Select Base Reward',
                border: OutlineInputBorder(),
              ),
              hint: const Text("Choose an existing reward"),
              items: baseRewards.map((p) {
                return DropdownMenuItem(value: p, child: Text(p.name));
              }).toList(),
              onChanged: (p) {
                if (p != null) {
                  setState(() {
                    selectedBaseRewardId = p.id;
                    nameController.text = p.name;
                    descriptionController.text = p.description;

                    if (selectedType == ListingType.promo) {
                      final qty =
                          int.tryParse(promoQuantityController.text) ?? 1;
                      pointsController.text =
                          ((p.originalPoints ?? p.points) * qty).toString();
                    } else {
                      pointsController.text =
                          (p.originalPoints ?? p.points).toString();
                    }

                    _syncSalePoints();
                    skuController.text = p.sku;
                    categories = List<String>.from(p.categories);
                    supplierController.text = p.supplier;
                    updateStockDisplay(baseRewards);
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
              children: baseRewards.map((p) {
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
                          final item = baseRewards.firstWhereOrNull(
                            (bp) => bp.name == itemName,
                          );
                          if (item != null) {
                            total += (item.originalPoints ?? item.points);
                          }
                        }
                        pointsController.text = total.toString();
                        _syncSalePoints();
                      }
                      _updateBundleSuppliers(baseRewards);
                      updateStockDisplay(baseRewards);
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
                  controller: pointsController,
                  decoration: InputDecoration(
                    labelText:
                        isDiscountable ? 'Original Points *' : 'Points *',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (isDiscountable) {
                        _syncSalePoints();
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
            enabled: !isBaseItem ||
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
                          color: isSelected
                              ? Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Colors.white
                              : Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.black87,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => _toggleCategory(cat),
                      selectedColor: Theme.of(context).primaryColor,
                      checkmarkColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onPrimary
                              : Colors.white,
                      showCheckmark: true,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.onPrimary
                                : Colors.white
                            : Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.black87,
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
                  final base = baseRewards.firstWhereOrNull(
                    (p) => p.id == selectedBaseRewardId,
                  );
                  if (base != null) {
                    pointsController.text =
                        ((base.originalPoints ?? base.points) * qty).toString();
                    _syncSalePoints();
                  }
                  updateStockDisplay(baseRewards);
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
                      widget.reward == null ? 'Create Listing' : 'Save Changes',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
