import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/core/widgets/icon_picker_field.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mynix_frontend/features/menu/services/duplicate_detector.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/dialogs/duplicate_warning_chip.dart';

void showAddRetailProductDialog(BuildContext context, {int? currentCategoryId, MenuItem? itemToEdit}) {
  final isEditing = itemToEdit != null;
  final nameController = TextEditingController(text: itemToEdit?.cleanName ?? '');
  final sortOrderController = TextEditingController(
    text: (itemToEdit != null && itemToEdit.sortOrder > 0) ? itemToEdit.sortOrder.toString() : '',
  );
  final sellingPriceController = TextEditingController(
    text: isEditing
        ? (itemToEdit.price % 1 == 0 ? itemToEdit.price.toInt().toString() : itemToEdit.price.toString())
        : '',
  );
  final barcodeController = TextEditingController(text: itemToEdit?.barcode ?? '');
  int? selectedCategoryId = currentCategoryId ?? int.tryParse(itemToEdit?.categoryId ?? '');
  String selectedUnit = 'pcs';
  String? selectedIcon = itemToEdit?.icon;
  final currency = context.read<SettingsBloc>().state.currency;

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          nameController.addListener(() {
            if (ctx.mounted) setState(() {});
          });
          barcodeController.addListener(() {
            if (ctx.mounted) setState(() {});
          });

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final inputBg = isDark ? AppColors.darkBg : AppColors.lightBg;

          final menuState = context.watch<MenuBloc>().state;
          DuplicateMatch<MenuItem>? duplicateMatch;
          if (menuState is MenuLoaded) {
            duplicateMatch = DuplicateDetector.findMenuItemDuplicate(
              items: menuState.items,
              queryName: nameController.text,
              queryBarcode: barcodeController.text,
              currentCategoryId: selectedCategoryId,
              excludeItemId: itemToEdit?.id,
            );
          }

          return MynixDialog(
            title: isEditing ? 'Редактировать товар' : 'Новый товар для витрины',
            icon: PhosphorIconsRegular.storefront,
            width: 520,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Название товара (Мясо, Вода, Сникерс)',
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.inputRadius,
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(PhosphorIconsRegular.storefront, color: AppColors.brandPrimary),
                    ),
                    autofocus: true,
                  ),
                  if (duplicateMatch != null)
                    DuplicateWarningChip(
                      message: duplicateMatch.matchReason,
                      onOpenExisting: () {
                        Navigator.pop(ctx);
                        showAddRetailProductDialog(
                          context,
                          currentCategoryId: selectedCategoryId,
                          itemToEdit: duplicateMatch!.item,
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, catState) {
                      final retailCategories = catState is CategoryLoaded
                          ? catState.categories.where((c) => c.categoryType == 'retail' && !c.isArchived).toList()
                          : [];

                      return DropdownButtonFormField<int?>(
                        initialValue: selectedCategoryId,
                        dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        decoration: InputDecoration(
                          labelText: 'Категория витрины',
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(
                            borderRadius: AppRadii.inputRadius,
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(PhosphorIconsRegular.folderPlus, color: AppColors.brandPrimary),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Без категории (в корень каталога)'),
                          ),
                          ...retailCategories.map(
                            (c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => selectedCategoryId = val),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: sellingPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Цена продажи на кассе',
                            suffixText: currency,
                            suffixStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                            ),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(
                              borderRadius: AppRadii.inputRadius,
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(PhosphorIconsRegular.tag, color: AppColors.brandPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedUnit,
                          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          decoration: InputDecoration(
                            labelText: 'Ед. изм.',
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(
                              borderRadius: AppRadii.inputRadius,
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(PhosphorIconsRegular.scales, color: AppColors.brandPrimary),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'pcs', child: Text('Шт (шт)')),
                            DropdownMenuItem(value: 'kg', child: Text('Кг (кг)')),
                            DropdownMenuItem(value: 'g', child: Text('Гр (г)')),
                            DropdownMenuItem(value: 'l', child: Text('Литр (л)')),
                            DropdownMenuItem(value: 'ml', child: Text('Мл (мл)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => selectedUnit = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: barcodeController,
                          decoration: InputDecoration(
                            labelText: 'Штрихкод (опционально)',
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(
                              borderRadius: AppRadii.inputRadius,
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(PhosphorIconsRegular.barcode, color: AppColors.brandPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: sortOrderController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Порядок в меню',
                            hintText: '1, 2, 3... (пусто = авто)',
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(
                              borderRadius: AppRadii.inputRadius,
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(PhosphorIconsRegular.sortAscending, color: AppColors.brandPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  IconPickerField(
                    selectedIcon: selectedIcon,
                    onIconSelected: (icon) {
                      setState(() {
                        selectedIcon = icon;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              AppGhostButton(
                label: 'Отмена',
                onPressed: () => Navigator.pop(ctx),
              ),
              const SizedBox(width: 12),
              AppPrimaryButton(
                label: isEditing ? 'Сохранить' : 'Создать',
                icon: PhosphorIconsRegular.floppyDisk,
                width: null,
                onPressed: duplicateMatch != null
                    ? null
                    : () {
                        final sPrice = double.tryParse(sellingPriceController.text.trim()) ?? 0.0;
                        final sortOrder = int.tryParse(sortOrderController.text.trim()) ?? 0;
                        final barcode = barcodeController.text.trim().isEmpty ? null : barcodeController.text.trim();

                        if (nameController.text.trim().isNotEmpty && sPrice >= 0) {
                          final Map<String, dynamic> attributes = {};
                          if (selectedIcon != null) {
                            attributes['icon'] = 'icon:$selectedIcon';
                          }
                          if (isEditing) {
                            final Map<String, dynamic> data = {
                              'name': nameController.text.trim(),
                              'price': sPrice,
                              'category_id': selectedCategoryId,
                              'sort_order': sortOrder,
                              'barcode': barcode,
                              if (attributes.isNotEmpty) 'attributes': attributes,
                            };
                            context.read<MenuBloc>().add(UpdateMenuItem(itemToEdit.id, data));
                          } else {
                            context.read<MenuBloc>().add(
                                  CreateRetailProduct(
                                    name: nameController.text.trim(),
                                    categoryId: selectedCategoryId,
                                    unit: selectedUnit,
                                    purchasePrice: 0.0,
                                    sellingPrice: sPrice,
                                    sortOrder: sortOrder,
                                    barcode: barcode,
                                    attributes: attributes.isNotEmpty ? attributes : null,
                                  ),
                                );
                          }
                          Navigator.pop(ctx);
                        }
                      },
              ),
            ],
          );
        },
      );
    },
  );
}
