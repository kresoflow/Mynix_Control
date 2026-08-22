import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/analytics/bloc/analytics_bloc.dart';
import 'package:mynix_frontend/features/analytics/bloc/analytics_event.dart';

class AnalyticsFilterBar extends StatelessWidget {
  final String selectedPeriod;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(String) onPeriodChanged;
  final Function(DateTime start, DateTime end) onCustomDateSelected;

  const AnalyticsFilterBar({
    super.key,
    required this.selectedPeriod,
    required this.startDate,
    required this.endDate,
    required this.onPeriodChanged,
    required this.onCustomDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 960;

          if (isWide) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Аналитика',
                      style: AppTextStyles.h3.copyWith(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 20),
                    _buildTabs(isDark),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPeriodPills(context, isDark),
                    const SizedBox(width: 8),
                    _buildCalendarButton(context, isDark),
                    const SizedBox(width: 8),
                    _buildRefreshButton(context, isDark),
                  ],
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Аналитика',
                    style: AppTextStyles.h3.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildRefreshButton(context, isDark),
                ],
              ),
              const SizedBox(height: 8),
              _buildTabs(isDark),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPeriodPills(context, isDark),
                    const SizedBox(width: 8),
                    _buildCalendarButton(context, isDark),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    return SizedBox(
      height: 36,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.brandPrimary,
        unselectedLabelColor: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        indicatorColor: AppColors.brandPrimary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
        tabs: const [
          Tab(text: 'Дашборд'),
          Tab(text: 'История заказов'),
          Tab(text: 'Кассовые смены'),
        ],
      ),
    );
  }

  Widget _buildPeriodPills(BuildContext context, bool isDark) {
    final periods = [
      ('today', 'Сегодня'),
      ('week', 'Неделя'),
      ('month', 'Месяц'),
      ('year', 'Год'),
    ];

    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: periods.map((p) {
          final isSelected = selectedPeriod == p.$1;
          return InkWell(
            onTap: () {
              onPeriodChanged(p.$1);
              context.read<AnalyticsBloc>().add(LoadAnalytics(period: p.$1));
            },
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                p.$2,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
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

  Widget _buildCalendarButton(BuildContext context, bool isDark) {
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
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark
                    ? ColorScheme.dark(primary: AppColors.brandPrimary)
                    : ColorScheme.light(primary: AppColors.brandPrimary),
              ),
              child: child!,
            );
          },
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.calendar,
              size: 14,
              color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
            ),
            const SizedBox(width: 6),
            Text(
              'Период',
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          PhosphorIconsRegular.arrowsClockwise,
          size: 18,
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
        tooltip: 'Обновить',
        onPressed: () {
          context.read<AnalyticsBloc>().add(
                LoadAnalytics(
                  period: selectedPeriod,
                  startDate: startDate,
                  endDate: endDate,
                ),
              );
        },
      ),
    );
  }
}
