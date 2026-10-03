// ==============================================================================
// МОДУЛЬ: Меню и Каталог / Poka-Yoke модальное окно архивации карточки с вариациями
// ДОМЕН: lib/features/menu/view/widgets/catalog/dialogs/catalog_variation_deletion_modal.dart
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

/// Отображает диалог безопасного выбора политики архивации карточки с вариациями.
void showVariationDeletionModal(BuildContext context, MenuItem item) {
  showDialog(
    context: context,
    builder: (ctx) => CatalogVariationDeletionModal(item: item),
  );
}

class CatalogVariationDeletionModal extends StatelessWidget {
  final MenuItem item;

  const CatalogVariationDeletionModal({super.key, required this.item});

  Widget _buildPolicyCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isDestructive)
            AppDangerButton(
              label: buttonLabel,
              size: AppButtonSize.sm,
              height: 32,
              onPressed: onPressed,
            )
          else if (isPrimary)
            AppPrimaryButton(
              label: buttonLabel,
              size: AppButtonSize.sm,
              height: 32,
              onPressed: onPressed,
            )
          else
            AppSecondaryButton(
              label: buttonLabel,
              size: AppButtonSize.sm,
              height: 32,
              onPressed: onPressed,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = item.cleanName;
    final varsSummary = item.variationsSummary ?? 'несколько фасовок';

    return AppDialog(
      title: 'Удаление карточки с вариациями',
      icon: PhosphorIconsRegular.shieldWarning,
      width: 540,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Карточка «$displayName» содержит $varsSummary. Выберите безопасное действие:',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildPolicyCard(
            context: context,
            icon: PhosphorIconsRegular.arrowsSplit,
            iconColor: AppColors.brandPrimary,
            title: 'Распаковать в отдельные товары',
            description: 'Каждая фасовка станет самостоятельным товаром в каталоге. Складские остатки не пострадают.',
            buttonLabel: 'Распаковать',
            isPrimary: true,
            onPressed: () {
              context.read<MenuBloc>().add(
                DeleteMenuItemWithPolicy(item.id, policy: 'unbundle'),
              );
              Navigator.pop(context);
            },
          ),
          _buildPolicyCard(
            context: context,
            icon: PhosphorIconsRegular.eyeSlash,
            iconColor: AppColors.info,
            title: 'Снять только с витрины',
            description: 'Карточка скроется из кассы и меню. Товары на складе останутся активными для учета.',
            buttonLabel: 'Скрыть витрину',
            onPressed: () {
              context.read<MenuBloc>().add(
                DeleteMenuItemWithPolicy(item.id, policy: 'archive_menu_only'),
              );
              Navigator.pop(context);
            },
          ),
          _buildPolicyCard(
            context: context,
            icon: PhosphorIconsRegular.archive,
            iconColor: AppColors.danger,
            title: 'Архивировать всё (витрина + склад)',
            description: 'Карточка меню и все её складские фасовки будут перемещены в архив.',
            buttonLabel: 'В архив',
            isDestructive: true,
            onPressed: () {
              context.read<MenuBloc>().add(
                DeleteMenuItemWithPolicy(item.id, policy: 'archive_all'),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [
        AppGhostButton(label: 'Отмена', onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
