// ==============================================================================
// МОДУЛЬ: Меню и Каталог / Диалог объединения товаров в одну карточку (Merge)
// ДОМЕН: lib/features/menu/view/widgets/catalog/dialogs/merge_items_dialog.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';

/// Открывает диалог объединения выбранных товаров в одну карточку.
void showMergeItemsDialog({
  required BuildContext context,
  required List<MenuItem> items,
  required VoidCallback onMerged,
}) {
  if (items.length < 2) return;
  showDialog(
    context: context,
    builder: (ctx) => MergeItemsDialog(items: items, onMerged: onMerged),
  );
}

class MergeItemsDialog extends StatefulWidget {
  final List<MenuItem> items;
  final VoidCallback onMerged;

  const MergeItemsDialog({
    super.key,
    required this.items,
    required this.onMerged,
  });

  @override
  State<MergeItemsDialog> createState() => _MergeItemsDialogState();
}

class _MergeItemsDialogState extends State<MergeItemsDialog> {
  late int _targetItemId;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _targetItemId = widget.items.first.id;

    // Вычисляем общее базовое имя или берем имя первого элемента
    final firstClean = widget.items.first.cleanName.trim();
    _nameController = TextEditingController(text: firstClean);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppDialog(
      title: 'Объединить в одну карточку',
      icon: PhosphorIconsRegular.unite,
      width: 500,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Выбранные ${widget.items.length} товаров будут объединены в одну карточку каталога с вариациями. Складские товары и остатки сохранятся.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Название объединенной карточки',
              prefixIcon: Icon(PhosphorIconsRegular.tag, color: AppColors.brandPrimary),
              filled: true,
              fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
              border: const OutlineInputBorder(borderRadius: AppRadii.inputRadius, borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Выберите основной товар:',
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: AppRadii.inputRadius,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (ctx, index) {
                final item = widget.items[index];
                final isSelected = item.id == _targetItemId;
                return ListTile(
                  dense: true,
                  selected: isSelected,
                  leading: Icon(
                    isSelected ? PhosphorIconsFill.radioButton : PhosphorIconsRegular.radioButton,
                    color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                    size: 20,
                  ),
                  title: Text(item.cleanName, style: AppTextStyles.bodyMedium),
                  subtitle: Text(
                    item.variationsSummary ?? 'Одиночный товар',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _targetItemId = item.id;
                      _nameController.text = item.cleanName.trim();
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        AppGhostButton(label: 'Отмена', onPressed: () => Navigator.pop(context)),
        const SizedBox(width: 8),
        AppPrimaryButton(
          label: 'Объединить',
          icon: PhosphorIconsRegular.unite,
          onPressed: () {
            final sourceIds = widget.items.map((i) => i.id).where((id) => id != _targetItemId).toList();
            context.read<MenuBloc>().add(
              MergeMenuItems(
                targetItemId: _targetItemId,
                sourceItemIds: sourceIds,
                targetName: _nameController.text.trim(),
              ),
            );
            Navigator.pop(context);
            widget.onMerged();
          },
        ),
      ],
    );
  }
}
