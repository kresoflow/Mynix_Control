import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/ui_kit/ui_kit.dart';

class ShowcaseDialogSection extends StatefulWidget {
  final bool isDark;

  const ShowcaseDialogSection({super.key, required this.isDark});

  @override
  State<ShowcaseDialogSection> createState() => _ShowcaseDialogSectionState();
}

class _ShowcaseDialogSectionState extends State<ShowcaseDialogSection> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('7. Поиск, Диалоги и Уведомления (AppSearchField, MynixDialog, AppToast)', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Инпуты тулбаров (36px MD), модальные окна со скруглениями 20px и всплывающие тосты.',
            style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AppSearchField(
                controller: _searchCtrl,
                hintText: 'Поиск по блюдам или SKU...',
                width: 300,
              ),
              const SizedBox(width: 12),
              AppPrimaryButton(
                label: 'Найти',
                icon: PhosphorIconsRegular.magnifyingGlass,
                size: AppButtonSize.md,
                onPressed: () => AppToast.showSuccess(context, 'Поиск: ${_searchCtrl.text}'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              AppPrimaryButton(
                label: 'Открыть тестовый диалог',
                icon: PhosphorIconsRegular.browsers,
                size: AppButtonSize.md,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => MynixDialog(
                      title: 'Стандартный Mynix Dialog',
                      icon: PhosphorIconsRegular.sparkle,
                      content: const Text(
                        'Это диалоговое окно использует скругления AppRadii.dialog (20px), кнопки размера LG и мягкие тени.',
                      ),
                      actions: [
                        AppGhostButton(label: 'Отмена', onPressed: () => Navigator.pop(ctx)),
                        const SizedBox(width: 8),
                        AppPrimaryButton(label: 'Подтвердить', onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  );
                },
              ),
              AppSecondaryButton(
                label: 'Уведомление (Toast)',
                icon: PhosphorIconsRegular.bell,
                size: AppButtonSize.md,
                onPressed: () => AppToast.showSuccess(context, 'Успешно обновлено!'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
