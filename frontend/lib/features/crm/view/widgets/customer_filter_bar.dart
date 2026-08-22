import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class CustomerFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String activeFilter;
  final int totalCount;
  final int vipCount;
  final int debtorsCount;
  final int depositsCount;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onFilterChanged;

  const CustomerFilterBar({
    super.key,
    required this.searchController,
    required this.activeFilter,
    required this.totalCount,
    required this.vipCount,
    required this.debtorsCount,
    required this.depositsCount,
    required this.onSearch,
    required this.onFilterChanged,
  });

  Widget _buildFilterPill(String label, String value, bool isDark, {IconData? icon}) {
    final isSelected = activeFilter == value;
    final fgColor = isSelected
        ? AppColors.darkBg
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return InkWell(
      onTap: () => onFilterChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fgColor),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Поиск по имени или телефону...',
              prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 18),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill('Все ($totalCount)', 'all', isDark),
              const SizedBox(width: 6),
              _buildFilterPill('VIP ($vipCount)', 'vip', isDark, icon: PhosphorIconsRegular.crown),
              const SizedBox(width: 6),
              _buildFilterPill('Спящие', 'churn', isDark, icon: PhosphorIconsRegular.moon),
              const SizedBox(width: 6),
              _buildFilterPill('Новички', 'new', isDark, icon: PhosphorIconsRegular.sparkle),
              const SizedBox(width: 6),
              _buildFilterPill('Должники ($debtorsCount)', 'debtors', isDark),
              const SizedBox(width: 6),
              _buildFilterPill('Депозиты ($depositsCount)', 'deposits', isDark),
            ],
          ),
        ),
      ],
    );
  }
}

