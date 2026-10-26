import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/features/analytics/bloc/analytics_bloc.dart';
import 'package:kreso_frontend/features/analytics/bloc/analytics_event.dart';
import 'package:kreso_frontend/features/analytics/bloc/analytics_state.dart';
import 'analytics_period_selector.dart';

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
    final isRefreshing = context.select<AnalyticsBloc, bool>((bloc) {
      final state = bloc.state;
      return state is AnalyticsLoaded && state.isRefreshing;
    });

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
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
                    AnalyticsPeriodSelector(
                      selectedPeriod: selectedPeriod,
                      startDate: startDate,
                      endDate: endDate,
                      onPeriodChanged: onPeriodChanged,
                      onCustomDateSelected: onCustomDateSelected,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildRefreshButton(context, isDark, isRefreshing),
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
                  _buildRefreshButton(context, isDark, isRefreshing),
                ],
              ),
              const SizedBox(height: 8),
              _buildTabs(isDark),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: AnalyticsPeriodSelector(
                  selectedPeriod: selectedPeriod,
                  startDate: startDate,
                  endDate: endDate,
                  onPeriodChanged: onPeriodChanged,
                  onCustomDateSelected: onCustomDateSelected,
                  isDark: isDark,
                ),
              ),
            ],
          );
        },
      ),
    ),
        if (isRefreshing)
          SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              color: AppColors.brandPrimary,
              backgroundColor: AppColors.transparent,
            ),
          ),
      ],
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

  Widget _buildRefreshButton(BuildContext context, bool isDark, bool isRefreshing) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: isRefreshing
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary),
              )
            : Icon(
                PhosphorIconsRegular.arrowsClockwise,
                size: 18,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
        tooltip: isRefreshing ? 'Обновление данных...' : 'Обновить',
        onPressed: isRefreshing
            ? null
            : () => context.read<AnalyticsBloc>().add(
                  LoadAnalytics(period: selectedPeriod, startDate: startDate, endDate: endDate),
                ),
      ),
    );
  }
}
