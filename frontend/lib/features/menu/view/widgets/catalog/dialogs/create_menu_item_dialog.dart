import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
void showAddMenuItemDialog(BuildContext context, {int? currentCategoryId, MenuItem? itemToEdit}) {
  final isEditing = itemToEdit != null;
  final nameController = TextEditingController(text: itemToEdit?.cleanName ?? '');
  final priceController = TextEditingController(text: itemToEdit?.price.toInt().toString() ?? '');
  
  int? selectedCategoryId = currentCategoryId;
  final currency = context.read<SettingsBloc>().state.currency;
  if (isEditing) {
    selectedCategoryId = int.tryParse(itemToEdit.categoryId);
  }

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return MynixDialog(
            title: isEditing ? 'Редактировать блюдо' : 'Новое блюдо',
            icon: PhosphorIconsRegular.cookingPot,
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Название блюда',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.inputRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    autofocus: !isEditing,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Цена ($currency)',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.inputRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, catState) {
                      if (catState is CategoryLoaded) {
                        final dishCategories = catState.categories.where((c) => c.categoryType == 'dish').toList();
                        return DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: 'Категория',
                            filled: true,
                            fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                            border: OutlineInputBorder(
                              borderRadius: AppRadii.inputRadius,
                              borderSide: BorderSide.none,
                            ),
                          ),
                          initialValue: selectedCategoryId,
                          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          items: [
                            const DropdownMenuItem<int>(value: null, child: Text('Без категории')),
                            ...dishCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (val) {
                            setState(() {
                              selectedCategoryId = val;
                            });
                          },
                        );
                      }
                      return const SizedBox.shrink();
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
                  final price = double.tryParse(priceController.text) ?? 0.0;
                  if (nameController.text.isNotEmpty && price > 0) {
                    if (isEditing) {
                      context.read<MenuBloc>().add(
                            UpdateMenuItem(
                              itemToEdit.id,
                              {
                                'name': nameController.text,
                                'price': price,
                                'category_id': selectedCategoryId,
                              },
                            ),
                          );
                    } else {
                      context.read<MenuBloc>().add(
                            CreateMenuItem(
                              name: nameController.text,
                              price: price,
                              category: selectedCategoryId?.toString() ?? '',
                            ),
                          );
                    }
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          );
        }
      );
    },
  );
}
