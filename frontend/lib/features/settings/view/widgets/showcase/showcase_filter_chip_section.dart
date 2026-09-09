import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/ui_kit/ui_kit.dart';

class ShowcaseFilterChipSection extends StatefulWidget {
  final bool isDark;

  const ShowcaseFilterChipSection({super.key, required this.isDark});

  @override
  State<ShowcaseFilterChipSection> createState() => _ShowcaseFilterChipSectionState();
}

class _ShowcaseFilterChipSectionState extends State<ShowcaseFilterChipSection> {
  String _crmFilter = 'all';
  String _recipeFilter = 'all';

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
          Text('6. Чипы и полосы фильтрации (AppFilterChip & AppFilterBar)', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Горизонтальная фильтрация списков и таблиц со встроенными бейджами количества.',
            style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          const SizedBox(height: 16),

          // CRM Filters
          Text('Пример 1: Фильтры гостей в CRM', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          AppFilterBar(
            children: [
              AppFilterChip(
                label: 'Все',
                count: 142,
                isSelected: _crmFilter == 'all',
                onTap: () => setState(() => _crmFilter = 'all'),
              ),
              AppFilterChip(
                label: 'VIP',
                count: 18,
                icon: PhosphorIconsRegular.crown,
                isSelected: _crmFilter == 'vip',
                onTap: () => setState(() => _crmFilter = 'vip'),
              ),
              AppFilterChip(
                label: 'Спящие',
                count: 24,
                icon: PhosphorIconsRegular.moon,
                isSelected: _crmFilter == 'churn',
                onTap: () => setState(() => _crmFilter = 'churn'),
              ),
              AppFilterChip(
                label: 'Новички',
                count: 9,
                icon: PhosphorIconsRegular.sparkle,
                isSelected: _crmFilter == 'new',
                onTap: () => setState(() => _crmFilter = 'new'),
              ),
              AppFilterChip(
                label: 'Должники',
                count: 5,
                isSelected: _crmFilter == 'debtors',
                onTap: () => setState(() => _crmFilter = 'debtors'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recipe Filters
          Text('Пример 2: Фильтры состава техкарт', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          AppFilterBar(
            children: [
              AppFilterChip(
                label: 'Все техкарты',
                count: 56,
                isSelected: _recipeFilter == 'all',
                onTap: () => setState(() => _recipeFilter = 'all'),
              ),
              AppFilterChip(
                label: 'С составом',
                count: 42,
                isSelected: _recipeFilter == 'with_ingredients',
                onTap: () => setState(() => _recipeFilter = 'with_ingredients'),
              ),
              AppFilterChip(
                label: 'Без состава',
                count: 14,
                isSelected: _recipeFilter == 'without_ingredients',
                onTap: () => setState(() => _recipeFilter = 'without_ingredients'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
