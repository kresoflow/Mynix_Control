import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/widgets/ui_kit/ui_kit.dart';

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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppSearchField(
            controller: searchController,
            onChanged: onSearch,
            hintText: 'Поиск по имени или телефону...',
          ),
        ),
        const SizedBox(width: 12),
        AppFilterBar(
          children: [
            AppFilterChip(
              label: 'Все',
              count: totalCount,
              isSelected: activeFilter == 'all',
              onTap: () => onFilterChanged('all'),
            ),
            AppFilterChip(
              label: 'VIP',
              count: vipCount,
              icon: PhosphorIconsRegular.crown,
              isSelected: activeFilter == 'vip',
              onTap: () => onFilterChanged('vip'),
            ),
            AppFilterChip(
              label: 'Спящие',
              icon: PhosphorIconsRegular.moon,
              isSelected: activeFilter == 'churn',
              onTap: () => onFilterChanged('churn'),
            ),
            AppFilterChip(
              label: 'Новички',
              icon: PhosphorIconsRegular.sparkle,
              isSelected: activeFilter == 'new',
              onTap: () => onFilterChanged('new'),
            ),
            AppFilterChip(
              label: 'Должники',
              count: debtorsCount,
              isSelected: activeFilter == 'debtors',
              onTap: () => onFilterChanged('debtors'),
            ),
            AppFilterChip(
              label: 'Депозиты',
              count: depositsCount,
              isSelected: activeFilter == 'deposits',
              onTap: () => onFilterChanged('deposits'),
            ),
          ],
        ),
      ],
    );
  }
}
