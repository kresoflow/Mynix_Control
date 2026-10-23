// ==============================================================================
// ВИТРИНА АРХИВА: МУЗЕЙ ДИЗАЙНА И ЛЕГАСИ-КОМПОНЕНТЫ (LEGACY SANDBOX)
// ==============================================================================
//
// [АРХИВ] Изолированная лаборатория для сравнительного тестирования старых
// компонентов первого поколения (AppDialog 450px, AppSegmentedTab).
// Выведены из публичного ui_kit.dart и защищены от случайного использования.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_segmented_tab.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

class ShowcaseLegacyArchiveSection extends StatefulWidget {
  final bool isDark;

  const ShowcaseLegacyArchiveSection({super.key, required this.isDark});

  @override
  State<ShowcaseLegacyArchiveSection> createState() => _ShowcaseLegacyArchiveSectionState();
}

class _ShowcaseLegacyArchiveSectionState extends State<ShowcaseLegacyArchiveSection> {
  int _legacyTabVal = 1;

  void _openLegacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AppDialog(
        title: 'Старый диалог (AppDialog 450 px)',
        icon: PhosphorIconsRegular.archive,
        width: 450,
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Это компонент первого поколения без фиксированных стандартов SM/MD/LG и без двухъярусного подвала.',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'Сравните его с новым AppDialogScaffold v2, где сумма находится строго над кнопкой проведения.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          AppGhostButton(label: 'Закрыть', onPressed: () => Navigator.pop(dialogCtx)),
          AppButton.secondary(label: 'Тест легаси', onPressed: () => Navigator.pop(dialogCtx)),
        ],
      ),
    );
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
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.8),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Шапка секции архива ──
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(PhosphorIconsRegular.archive, size: 18, color: Colors.grey),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '12. Архив компонентов (Legacy Sandbox)',
                      style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Компоненты первого поколения, изолированные из ui_kit.dart для сравнительного анализа.',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
              ),
              const AppStatusBadge(
                label: 'ИЗОЛИРОВАН',
                variant: AppBadgeVariant.neutral,
                hasDot: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ── Сравнение 1: Старый селектор табов ──
          Text(
            'Старый селектор первого поколения (AppSegmentedTab 40px):',
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          AppSegmentedTab<int>(
            selectedValue: _legacyTabVal,
            height: 38,
            onValueChanged: (val) => setState(() => _legacyTabVal = val),
            items: const [
              AppSegmentedTabItem(value: 1, label: 'Легаси Таб 1', icon: PhosphorIconsRegular.folder),
              AppSegmentedTabItem(value: 2, label: 'Легаси Таб 2', icon: PhosphorIconsRegular.gear),
              AppSegmentedTabItem(value: 3, label: 'Легаси Таб 3', icon: PhosphorIconsRegular.bell),
            ],
          ),
          const SizedBox(height: 18),

          // ── Сравнение 2: Старый диалог ──
          Row(
            children: [
              AppButton.secondary(
                label: 'Открыть старый AppDialog (450 px)',
                icon: PhosphorIconsRegular.arrowSquareOut,
                size: AppButtonSize.sm,
                onPressed: () => _openLegacyDialog(context),
              ),
              const SizedBox(width: 12),
              Text(
                '← Сравнить со стандартом AppDialogScaffold v2 (SM / MD / LG)',
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
