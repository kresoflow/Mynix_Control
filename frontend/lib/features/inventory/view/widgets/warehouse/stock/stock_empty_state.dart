// ==============================================================================
// МОДУЛЬ: Склад / Компонент пустого состояния остатков (Stock Empty State)
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/stock/stock_empty_state.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ─── 1. Виджет пустого состояния таблицы остатков ────────────────────────────

/// [UI-KIT] Отображает контекстное пустое состояние при поиске или фильтрации,
/// сохраняя окружающий экран (шапку, тулбар поиска и сайдбар) полностью активным.
class StockEmptyState extends StatelessWidget {
  final String searchQuery;
  final String filter;
  final VoidCallback onReset;

  const StockEmptyState({
    super.key,
    required this.searchQuery,
    required this.filter,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSearchActive = searchQuery.isNotEmpty;
    final isFilterActive = filter != 'all';

    final title = isSearchActive
        ? 'Ничего не найдено по запросу «$searchQuery»'
        : (isFilterActive
            ? 'Нет позиций в выбранной категории'
            : 'Склад пуст');

    final subtitle = isSearchActive
        ? 'Проверьте правильность написания названия, артикула или штрихкода'
        : (isFilterActive
            ? 'Попробуйте переключить категорию или сбросить фильтрацию'
            : 'Поступлений товаров и сырья еще не зафиксировано');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
                boxShadow: AppShadows.card,
              ),
              child: Center(
                child: Icon(
                  isSearchActive
                      ? PhosphorIconsRegular.magnifyingGlass
                      : PhosphorIconsRegular.package,
                  size: 30,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 13,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ),
            if (isSearchActive || isFilterActive) ...[
              const SizedBox(height: 20),
              AppSecondaryButton(
                label: 'Сбросить фильтры и поиск',
                icon: PhosphorIconsRegular.arrowCounterClockwise,
                onPressed: onReset,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
