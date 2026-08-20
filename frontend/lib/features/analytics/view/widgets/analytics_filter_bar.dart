import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: isDesktop
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Аналитика',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(width: 32),
                    SizedBox(
                      width: 440,
                      child: TabBar(
                        labelColor: AppColors.brandPrimary,
                        unselectedLabelColor: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        indicatorColor: AppColors.brandPrimary,
                        tabs: const [
                          Tab(text: 'Дашборд'),
                          Tab(text: 'История заказов'),
                          Tab(text: 'Кассовые смены'),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildFilterButton('today', 'Сегодня', context),
                    const SizedBox(width: 8),
                    _buildFilterButton('week', 'Неделя', context),
                    const SizedBox(width: 8),
                    _buildFilterButton('month', 'Месяц', context),
                    const SizedBox(width: 8),
                    _buildFilterButton('year', 'Год', context),
                    const SizedBox(width: 8),
                    _buildCalendarButton(context),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        PhosphorIconsRegular.arrowsClockwise,
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
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Аналитика',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 8),
                TabBar(
                  labelColor: AppColors.brandPrimary,
                  unselectedLabelColor: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  indicatorColor: AppColors.brandPrimary,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Дашборд'),
                    Tab(text: 'История заказов'),
                    Tab(text: 'Кассовые смены'),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterButton('today', 'Сегодня', context),
                      const SizedBox(width: 8),
                      _buildFilterButton('week', 'Неделя', context),
                      const SizedBox(width: 8),
                      _buildFilterButton('month', 'Месяц', context),
                      const SizedBox(width: 8),
                      _buildFilterButton('year', 'Год', context),
                      const SizedBox(width: 8),
                      _buildCalendarButton(context),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          PhosphorIconsRegular.arrowsClockwise,
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
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterButton(String period, String label, BuildContext context) {
    final isSelected = selectedPeriod == period;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        onPeriodChanged(period);
        context.read<AnalyticsBloc>().add(LoadAnalytics(period: period));
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarButton(BuildContext context) {
    final isSelected = selectedPeriod == 'custom';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              data: theme.copyWith(
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
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIconsRegular.calendar,
              size: 16,
              color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
            ),
            const SizedBox(width: 6),
            Text(
              'Период',
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
