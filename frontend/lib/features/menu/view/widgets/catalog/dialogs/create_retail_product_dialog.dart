import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
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
  const String selectedUnit = 'pcs';
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
          DuplicateMatch? duplicateMatch;
          if (menuState is MenuLoaded) {
            duplicateMatch = DuplicateDetector.findMenuItemDuplicate(
              items: menuState.items,
              queryName: nameController.text,
              queryBarcode: barcodeController.text,
              currentCategoryId: currentCategoryId,
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
                      labelText: 'Название товара (Сникерс, Кола, Вода)',
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
                          currentCategoryId: currentCategoryId,
                          itemToEdit: duplicateMatch!.item,
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
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
                onPressed: () {
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
                        'sort_order': sortOrder,
                        'barcode': barcode,
                        if (attributes.isNotEmpty) 'attributes': attributes,
                      };
                      context.read<MenuBloc>().add(UpdateMenuItem(itemToEdit.id, data));
                    } else {
                      context.read<MenuBloc>().add(
                            CreateRetailProduct(
                              name: nameController.text.trim(),
                              categoryId: currentCategoryId ?? 0,
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
