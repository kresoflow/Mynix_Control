import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/ui_kit/ui_kit.dart';

class ShowcaseMenuButtonSection extends StatefulWidget {
  final bool isDark;

  const ShowcaseMenuButtonSection({super.key, required this.isDark});

  @override
  State<ShowcaseMenuButtonSection> createState() => _ShowcaseMenuButtonSectionState();
}

class _ShowcaseMenuButtonSectionState extends State<ShowcaseMenuButtonSection> {
  String _selectedMenuItem = 'None';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('2. Выпадающие кнопки действий (AppMenuButton)', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Единая кнопка со встроенным попапом действий (замена громоздким PopupMenuButton).',
            style: AppTextStyles.caption.copyWith(color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppMenuButton(
                label: 'Добавить в меню',
                icon: PhosphorIconsRegular.plus,
                size: AppButtonSize.md,
                items: const [
                  AppMenuItem(id: 'dish', label: 'Блюдо', icon: PhosphorIconsRegular.hamburger, shortcut: 'Ctrl+B'),
                  AppMenuItem(id: 'category', label: 'Категория блюд', icon: PhosphorIconsRegular.folderPlus),
                  AppMenuDivider(),
                  AppMenuItem(id: 'bulk', label: 'Пакетный ввод', icon: PhosphorIconsRegular.table),
                ],
                onSelected: (val) => setState(() => _selectedMenuItem = 'Menu: $val'),
              ),
              AppMenuButton(
                label: 'Складские действия',
                icon: PhosphorIconsRegular.archive,
                size: AppButtonSize.md,
                variant: AppButtonVariant.secondary,
                items: const [
                  AppMenuItem(id: 'receive', label: 'Оформить приход', icon: PhosphorIconsRegular.truck),
                  AppMenuItem(id: 'writeoff', label: 'Списание сырья', icon: PhosphorIconsRegular.trashSimple),
                  AppMenuItem(id: 'inventory', label: 'Инвентаризация', icon: PhosphorIconsRegular.clipboardText),
                ],
                onSelected: (val) => setState(() => _selectedMenuItem = 'Warehouse: $val'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isDark ? AppColors.darkCardHover : AppColors.lightCardHover,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Выбрано: $_selectedMenuItem',
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
