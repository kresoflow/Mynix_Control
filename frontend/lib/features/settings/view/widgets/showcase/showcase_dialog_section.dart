import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

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
          // Search Sizes Showcase
          Text('Шкала размеров поиска (AppSearchFieldSize):', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: const [
              AppSearchField(
                size: AppSearchFieldSize.sm,
                width: 210,
                hintText: 'SM (34px) Сайдбар...',
                shortcutHint: 'Ctrl+F',
              ),
              AppSearchField(
                size: AppSearchFieldSize.md,
                width: 250,
                hintText: 'MD (38px) Тулбар...',
                shortcutHint: 'Ctrl+F',
              ),
              AppSearchField(
                size: AppSearchFieldSize.lg,
                width: 290,
                hintText: 'LG (46px) Модалка/POS...',
                shortcutHint: '⌘K',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Collapsible Search Mode Showcase
          Text('Раскрывающийся режим (AppSearchMode.collapsible для POS/узких тулбаров):', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              AppSearchField(
                mode: AppSearchMode.collapsible,
                size: AppSearchFieldSize.md,
                hintText: 'Поиск блюд...',
                shortcutHint: 'Ctrl+F',
                width: 260,
                onChanged: (val) {},
              ),
              const SizedBox(width: 12),
              Text(
                '← Нажмите на лупу для раскрытия строки поиска с автофокусом',
                style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                    builder: (ctx) => AppDialogScaffold(
                      title: 'Стандартный диалог Kreso Flow (v2)',
                      icon: PhosphorIconsRegular.sparkle,
                      dialogSize: AppDialogSize.sm,
                      body: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Это диалоговое окно использует золотой стандарт AppDialogScaffold v2, скругления AppRadii.dialog, кнопки UI Kit и адаптивные размеры.',
                        ),
                      ),
                      actions: [
                        AppGhostButton(label: 'Отмена', onPressed: () => Navigator.pop(ctx)),
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
