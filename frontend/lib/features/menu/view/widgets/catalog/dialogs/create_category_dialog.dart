import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_event.dart';
import 'package:mynix_frontend/core/widgets/icon_picker_field.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void showAddCategoryDialog(BuildContext context, {int? currentCategoryId, dynamic itemToEdit, String type = 'dish', bool isBulk = false}) {
  final isEditing = itemToEdit != null;
  final nameController = TextEditingController(text: itemToEdit?.name ?? '');
  final sortOrderController = TextEditingController(text: isEditing ? itemToEdit.sortOrder.toString() : '');
  bool isVisible = itemToEdit?.isVisible ?? true;
  String selectedIcon = itemToEdit?.icon ?? '';

  showDialog(
    context: context,
    builder: (ctx) {
      int parsedCount = 0;
      
      void updateCount() {
        final count = nameController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).length;
        if (count != parsedCount) {
          parsedCount = count;
        }
      }

      return StatefulBuilder(
        builder: (context, setState) {
          nameController.addListener(() {
            final count = nameController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).length;
            if (count != parsedCount) {
              setState(() {
                parsedCount = count;
              });
            }
          });

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final titleText = isEditing ? 'Редактировать категорию' : (isBulk ? 'Массовое создание категорий' : 'Новая категория');

          return MynixDialog(
            title: titleText,
            icon: PhosphorIconsRegular.folderPlus,
            width: 500,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: isEditing ? 'Название категории' : (isBulk ? 'Список названий (каждая с новой строки)' : 'Названия (можно несколько с новой строки)'),
                    filled: true,
                    fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.inputRadius,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: (isEditing || !isBulk) ? (isEditing ? 1 : 5) : 10,
                  minLines: 1,
                  autofocus: true,
                ),
                if (!isEditing && parsedCount > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text('Будет создано: $parsedCount'),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: sortOrderController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Порядок сортировки',
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
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : AppColors.lightBg,
                    borderRadius: AppRadii.inputRadius,
                  ),
                  child: SwitchListTile(
                    title: const Text('Отображать на кассе'),
                    value: isVisible,
                    activeColor: AppColors.brandPrimary,
                    shape: RoundedRectangleBorder(borderRadius: AppRadii.inputRadius),
                    onChanged: (val) {
                      setState(() {
                        isVisible = val;
                      });
                    },
                  ),
                ),
              ],
            ),
            actions: [
              AppGhostButton(
                label: 'Отмена',
                onPressed: () => Navigator.pop(ctx),
              ),
              const SizedBox(width: 12),
              AppPrimaryButton(
                label: isEditing ? 'Сохранить' : (parsedCount > 1 ? 'Создать $parsedCount категорий' : 'Создать'),
                icon: PhosphorIconsRegular.floppyDisk,
                width: parsedCount > 1 ? 240 : 140,
                onPressed: () {
                  final sortOrder = int.tryParse(sortOrderController.text) ?? 0;
                  final finalIcon = (selectedIcon == '') ? null : selectedIcon;
                  
                  if (nameController.text.isNotEmpty) {
                    if (isEditing) {
                      context.read<CategoryBloc>().add(
                            UpdateCategory(
                              id: itemToEdit.id,
                              name: nameController.text.trim(),
                              sortOrder: sortOrder,
                              isVisible: isVisible,
                              icon: finalIcon,
                            ),
                          );
                    } else {
                      final names = nameController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                      
                      if (names.length == 1) {
                         context.read<CategoryBloc>().add(
                              CreateCategory(
                                name: names.first,
                                categoryType: type,
                                parentId: currentCategoryId,
                                sortOrder: sortOrder,
                                isVisible: isVisible,
                                icon: finalIcon,
                              ),
                            );
                      } else if (names.length > 1) {
                         int currentSortOrder = sortOrder;
                         final bulkData = <Map<String, dynamic>>[];
                         for (final name in names) {
                           bulkData.add({
                             'name': name,
                             'category_type': type,
                             'parent_id': currentCategoryId,
                             'sort_order': currentSortOrder,
                             'is_visible': isVisible,
                             'icon': finalIcon,
                           });
                           currentSortOrder += 10;
                         }
                         context.read<CategoryBloc>().add(CreateCategoriesBulk(categories: bulkData));
                      }
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
