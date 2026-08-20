import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

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

  Widget _buildFilterPill(String label, String value, bool isDark) {
    final isSelected = activeFilter == value;
    return InkWell(
      onTap: () => onFilterChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
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
              _buildFilterPill('🔥 VIP ($vipCount)', 'vip', isDark),
              const SizedBox(width: 6),
              _buildFilterPill('⚠️ Спящие', 'churn', isDark),
              const SizedBox(width: 6),
              _buildFilterPill('✨ Новички', 'new', isDark),
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
