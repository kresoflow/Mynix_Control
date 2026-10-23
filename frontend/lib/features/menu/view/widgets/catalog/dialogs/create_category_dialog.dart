import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/core/widgets/icon_picker_field.dart';
import 'package:kreso_frontend/core/widgets/color_picker/color_picker_field.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:kreso_frontend/features/menu/services/duplicate_detector.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/dialogs/duplicate_warning_chip.dart';

void showAddCategoryDialog(BuildContext context, {int? currentCategoryId, dynamic itemToEdit, String type = 'dish', bool isBulk = false}) {
  final isEditing = itemToEdit != null;
  final nameController = TextEditingController(text: itemToEdit?.name ?? '');
  final sortOrderController = TextEditingController(text: isEditing ? itemToEdit.sortOrder.toString() : '');
  bool isVisible = itemToEdit?.isVisible ?? true;
  String selectedIcon = itemToEdit?.icon ?? '';
  String? selectedColor = itemToEdit?.color;

  showDialog(
    context: context,
    builder: (ctx) {
      int parsedCount = 0;

      return StatefulBuilder(
        builder: (context, setState) {
          nameController.addListener(() {
            final count = nameController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).length;
            if (count != parsedCount) {
              setState(() {
                parsedCount = count;
              });
            } else {
              setState(() {});
            }
          });

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final titleText = isEditing ? 'Редактировать категорию' : (isBulk ? 'Массовое создание категорий' : 'Новая категория');

          final catState = context.watch<CategoryBloc>().state;
          DuplicateMatch? duplicateMatch;
          if (catState is CategoryLoaded && !isBulk && nameController.text.trim().isNotEmpty) {
            duplicateMatch = DuplicateDetector.findCategoryDuplicate(
              categories: catState.categories,
              queryName: nameController.text.trim(),
              categoryType: type,
              excludeCategoryId: itemToEdit?.id,
            );
          }

          void showDuplicateBlockedDialog(BuildContext dialogCtx, dynamic existingItem) {
            showDialog(
              context: dialogCtx,
              builder: (alertCtx) => AppDialog(
                title: 'Категория уже существует',
                icon: PhosphorIconsRegular.warningCircle,
                width: 440,
                content: Text(
                  'Категория «${existingItem.name}» уже есть в каталоге.\n\nОткрыть существующую категорию для редактирования?',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                actions: [
                  AppGhostButton(
                    label: 'Отмена',
                    onPressed: () => Navigator.pop(alertCtx),
                  ),
                  AppPrimaryButton(
                    label: 'Открыть карточку',
                    icon: PhosphorIconsRegular.arrowSquareOut,
                    onPressed: () {
                      Navigator.pop(alertCtx);
                      Navigator.pop(dialogCtx);
                      showAddCategoryDialog(
                        context,
                        currentCategoryId: currentCategoryId,
                        itemToEdit: existingItem,
                        type: type,
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return AppDialog(
            title: titleText,
            icon: PhosphorIconsRegular.folderPlus,
            width: 460,
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
                if (duplicateMatch != null)
                  DuplicateWarningChip(
                    message: duplicateMatch.matchReason,
                    onOpenExisting: () {
                      Navigator.pop(ctx);
                      showAddCategoryDialog(
                        context,
                        currentCategoryId: currentCategoryId,
                        itemToEdit: duplicateMatch!.item,
                        type: type,
                      );
                    },
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
                ColorPickerField(
                  selectedColor: selectedColor,
                  onColorSelected: (color) {
                    setState(() {
                      selectedColor = color;
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
                    activeThumbColor: AppColors.brandPrimary,
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
              AppPrimaryButton(
                label: isEditing ? 'Сохранить' : (parsedCount > 1 ? 'Создать $parsedCount категорий' : 'Создать'),
                icon: PhosphorIconsRegular.floppyDisk,
                width: null,
                onPressed: () {
                  int defaultSort = 1;
                  final catState = context.read<CategoryBloc>().state;
                  if (catState is CategoryLoaded) {
                    final sameType = catState.categories.where((c) => c.categoryType == type).toList();
                    defaultSort = sameType.length + 1;
                  }
                  final sortOrder = int.tryParse(sortOrderController.text) ?? defaultSort;
                  final finalIcon = selectedIcon;
                  final finalColor = selectedColor;
                  
                  if (nameController.text.isNotEmpty) {
                    if (!isEditing && !isBulk && duplicateMatch != null) {
                      showDuplicateBlockedDialog(ctx, duplicateMatch.item);
                      return;
                    }

                    if (isEditing) {
                      context.read<CategoryBloc>().add(
                            UpdateCategory(
                              id: itemToEdit.id,
                              name: nameController.text.trim(),
                              sortOrder: sortOrder,
                              color: finalColor,
                              resetColor: finalColor == null,
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
                                color: finalColor,
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
                             'color': finalColor,
                             'is_visible': isVisible,
                             'icon': finalIcon,
                           });
                           currentSortOrder += 1;
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
