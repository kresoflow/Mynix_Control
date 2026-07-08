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
void showAddRetailProductDialog(BuildContext context, {int? currentCategoryId, MenuItem? itemToEdit}) {
  final isEditing = itemToEdit != null;
  final nameController = TextEditingController(text: itemToEdit?.cleanName ?? '');
  
  final sellingPriceController = TextEditingController(text: isEditing ? itemToEdit.price.toInt().toString() : '');
  String selectedUnit = 'pcs';
  String? selectedIcon;
  final currency = context.read<SettingsBloc>().state.currency;

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return MynixDialog(
            title: isEditing ? 'Редактировать товар' : 'Новый товар для витрины',
            icon: PhosphorIconsRegular.storefront,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Название товара (Сникерс, Кола)',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.inputRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: sellingPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Цена продажи на кассе ($currency)',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.inputRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
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
                width: 140,
                onPressed: () {
                  final sPrice = double.tryParse(sellingPriceController.text) ?? 0.0;
                  if (nameController.text.isNotEmpty && sPrice > 0) {
                    final Map<String, dynamic> attributes = {};
                    if (selectedIcon != null) {
                      attributes['icon'] = 'icon:$selectedIcon';
                    }
                    if (isEditing) {
                      final Map<String, dynamic> data = {
                        'name': nameController.text,
                        'price': sPrice,
                      };
                      if (attributes.isNotEmpty) data['attributes'] = attributes;
                      context.read<MenuBloc>().add(UpdateRetailProduct(itemToEdit.id, data));
                    } else {
                      context.read<MenuBloc>().add(
                            CreateRetailProduct(
                              name: nameController.text,
                              categoryId: currentCategoryId ?? 0,
                              unit: selectedUnit,
                              purchasePrice: 0.0,
                              sellingPrice: sPrice,
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
