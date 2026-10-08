import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

class ShowcaseFilterChipSection extends StatefulWidget {
  final bool isDark;

  const ShowcaseFilterChipSection({super.key, required this.isDark});

  @override
  State<ShowcaseFilterChipSection> createState() => _ShowcaseFilterChipSectionState();
}

class _ShowcaseFilterChipSectionState extends State<ShowcaseFilterChipSection> {
  String _crmFilter = 'all';
  String _recipeFilter = 'all';
  String? _selectedTable = 'VIP 1';
  String? _selectedCustomer = 'Александр В.';
  bool _sizeSmSelected = false;
  bool _sizeMdSelected = true;
  bool _sizeLgSelected = false;

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
          Text('6. Чипы фильтрации и контекста (AppFilterChip & AppOrderContextChip)', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Горизонтальная фильтрация таблиц и компактные бейджи контекста заказа (стол, гость).',
            style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          const SizedBox(height: 16),

          // Sizes Showcase
          Text('Шкала размеров (AppFilterChipSize):', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppFilterChip(
                size: AppFilterChipSize.sm,
                label: 'SM (26px) Сайдбар',
                count: 14,
                isSelected: _sizeSmSelected,
                onTap: () => setState(() => _sizeSmSelected = !_sizeSmSelected),
              ),
              AppFilterChip(
                size: AppFilterChipSize.md,
                label: 'MD (32px) Таблицы',
                count: 42,
                isSelected: _sizeMdSelected,
                onTap: () => setState(() => _sizeMdSelected = !_sizeMdSelected),
              ),
              AppFilterChip(
                size: AppFilterChipSize.lg,
                label: 'LG (40px) Сенсор/POS',
                count: 99,
                icon: PhosphorIconsRegular.handTap,
                isSelected: _sizeLgSelected,
                onTap: () => setState(() => _sizeLgSelected = !_sizeLgSelected),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CRM Filters (MD Standard)
          Text('Пример 1: Фильтры гостей в CRM (Размер MD)', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          AppFilterBar(
            children: [
              AppFilterChip(
                size: AppFilterChipSize.md,
                label: 'Все',
                count: 142,
                isSelected: _crmFilter == 'all',
                onTap: () => setState(() => _crmFilter = 'all'),
              ),
              AppFilterChip(
                size: AppFilterChipSize.md,
                label: 'VIP',
                count: 18,
                icon: PhosphorIconsRegular.crown,
                isSelected: _crmFilter == 'vip',
                onTap: () => setState(() => _crmFilter = 'vip'),
              ),
              AppFilterChip(
                size: AppFilterChipSize.md,
                label: 'Спящие',
                count: 24,
                icon: PhosphorIconsRegular.moon,
                isSelected: _crmFilter == 'churn',
                onTap: () => setState(() => _crmFilter = 'churn'),
              ),
              AppFilterChip(
                size: AppFilterChipSize.md,
                label: 'Новички',
                count: 9,
                icon: PhosphorIconsRegular.sparkle,
                isSelected: _crmFilter == 'new',
                onTap: () => setState(() => _crmFilter = 'new'),
              ),
              AppFilterChip(
                size: AppFilterChipSize.md,
                label: 'Должники',
                count: 5,
                isSelected: _crmFilter == 'debtors',
                onTap: () => setState(() => _crmFilter = 'debtors'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recipe Filters (SM Compact)
          Text('Пример 2: Компактные фильтры сайдбара техкарт (Размер SM)', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          AppFilterBar(
            spacing: 4,
            children: [
              AppFilterChip(
                size: AppFilterChipSize.sm,
                label: 'Все блюда',
                count: 56,
                isSelected: _recipeFilter == 'all',
                onTap: () => setState(() => _recipeFilter = 'all'),
              ),
              AppFilterChip(
                size: AppFilterChipSize.sm,
                label: 'С составом',
                count: 42,
                activeColor: AppColors.success,
                isSelected: _recipeFilter == 'with_ingredients',
                onTap: () => setState(() => _recipeFilter = 'with_ingredients'),
              ),
              AppFilterChip(
                size: AppFilterChipSize.sm,
                label: 'Без состава',
                count: 14,
                activeColor: AppColors.warning,
                isSelected: _recipeFilter == 'without_ingredients',
                onTap: () => setState(() => _recipeFilter = 'without_ingredients'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Order Context Chips (POS Table & Customer)
          Text('Пример 3: Контекстные чипы заказа (AppOrderContextChip)', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppOrderContextChip(
                label: _selectedTable ?? 'Выбрать столик',
                icon: PhosphorIconsBold.chair,
                isSelected: _selectedTable != null,
                onTap: () => setState(() => _selectedTable = _selectedTable == null ? 'VIP 1' : null),
                onClear: () => setState(() => _selectedTable = null),
              ),
              AppOrderContextChip(
                label: _selectedCustomer ?? 'Выбрать гостя',
                icon: PhosphorIconsRegular.userCheck,
                isSelected: _selectedCustomer != null,
                onTap: () => setState(() => _selectedCustomer = _selectedCustomer == null ? 'Александр В.' : null),
                onClear: () => setState(() => _selectedCustomer = null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
