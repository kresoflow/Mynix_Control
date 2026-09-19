import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

class ShowcaseNavTileSection extends StatelessWidget {
  final bool isDark;

  const ShowcaseNavTileSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
          Text('4. Элементы списков и деревьев (AppNavTile: SM, MD, LG)', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Унифицированный компонент для сайдбаров, категорий склада, техкарт и настроек.',
            style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Size SM
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SM (32px) — Вложенные папки', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      AppNavTile(
                        title: 'Мясо и птица',
                        count: 12,
                        size: AppNavTileSize.sm,
                        isExpandable: true,
                        isExpanded: true,
                        isSelected: false,
                        onTap: () {},
                      ),
                      AppNavTile(
                        title: 'Говядина вырезка',
                        size: AppNavTileSize.sm,
                        depth: 1,
                        isSelected: true,
                        onTap: () {},
                      ),
                      AppNavTile(
                        title: 'Куриное филе',
                        size: AppNavTileSize.sm,
                        depth: 1,
                        isSelected: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Size MD
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MD (38px) — Стандарт категорий', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      AppNavTile(
                        title: 'ВСЕ СЫРЬЕ',
                        count: 48,
                        size: AppNavTileSize.md,
                        isSelected: true,
                        onTap: () {},
                      ),
                      AppNavTile(
                        title: 'Бургеры и снеки',
                        icon: PhosphorIconsRegular.hamburger,
                        count: 14,
                        size: AppNavTileSize.md,
                        isSelected: false,
                        onTap: () {},
                      ),
                      AppNavTile(
                        title: 'Холодные напитки',
                        icon: PhosphorIconsRegular.brandy,
                        count: 8,
                        size: AppNavTileSize.md,
                        isSelected: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Size LG
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LG (48px) — Сайдбар / Настройки', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      AppNavTile(
                        title: 'Основные настройки',
                        subtitle: 'KDS, склад, чеки',
                        icon: PhosphorIconsRegular.sliders,
                        size: AppNavTileSize.lg,
                        isSelected: true,
                        onTap: () {},
                      ),
                      AppNavTile(
                        title: 'Оборудование',
                        subtitle: 'Принтеры и фискал',
                        icon: PhosphorIconsRegular.printer,
                        size: AppNavTileSize.lg,
                        isSelected: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
