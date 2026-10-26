// ==============================================================================
// Title: AnalyticsPeriodSelector (analytics_period_selector.dart)
// Path: frontend/lib/features/analytics/view/widgets/analytics_period_selector.dart
// Description: Блок быстрых переключателей периодов и выбора диапазона дат.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/features/analytics/bloc/analytics_bloc.dart';
import 'package:kreso_frontend/features/analytics/bloc/analytics_event.dart';

// ─── 1. Виджет выбора аналитического периода ──────────────────────────────────

/// [UI-KIT] Компонент выбора периода аналитики (Сегодня, Неделя, Месяц, Год, Календарь)
class AnalyticsPeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(String) onPeriodChanged;
  final Function(DateTime start, DateTime end) onCustomDateSelected;
  final bool isDark;

  const AnalyticsPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.startDate,
    required this.endDate,
    required this.onPeriodChanged,
    required this.onCustomDateSelected,
    required this.isDark,
  });

  static const List<(String, String)> _periods = [
    ('today', 'Сегодня'),
    ('week', 'Неделя'),
    ('month', 'Месяц'),
    ('year', 'Год'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPeriodPills(context),
        const SizedBox(width: 8),
        _buildCalendarButton(context),
      ],
    );
  }

  Widget _buildPeriodPills(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadii.inputRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _periods.map((p) {
          final isSelected = selectedPeriod == p.$1;
          return InkWell(
            onTap: () {
              onPeriodChanged(p.$1);
              context.read<AnalyticsBloc>().add(LoadAnalytics(period: p.$1));
            },
            borderRadius: AppRadii.badgeRadius,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandPrimary : AppColors.transparent,
                borderRadius: AppRadii.badgeRadius,
              ),
              child: Text(
                p.$2,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.pureWhite
                      : (isDark ? AppColors.darkText : AppColors.lightText),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarButton(BuildContext context) {
    final isSelected = selectedPeriod == 'custom';

    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: startDate != null && endDate != null
              ? DateTimeRange(start: startDate!, end: endDate!)
              : null,
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? ColorScheme.dark(primary: AppColors.brandPrimary)
                  : ColorScheme.light(primary: AppColors.brandPrimary),
            ),
            child: child!,
          ),
        );

        if (picked != null) {
          onCustomDateSelected(picked.start, picked.end);
          if (context.mounted) {
            context.read<AnalyticsBloc>().add(
                  LoadAnalytics(
                    period: 'custom',
                    startDate: picked.start,
                    endDate: picked.end,
                  ),
                );
          }
        }
      },
      borderRadius: AppRadii.inputRadius,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: AppRadii.inputRadius,
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.calendar,
              size: 14,
              color: isSelected
                  ? AppColors.pureWhite
                  : (isDark ? AppColors.darkText : AppColors.lightText),
            ),
            const SizedBox(width: 6),
            Text(
              'Период',
              style: TextStyle(
                color: isSelected
                    ? AppColors.pureWhite
                    : (isDark ? AppColors.darkText : AppColors.lightText),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
