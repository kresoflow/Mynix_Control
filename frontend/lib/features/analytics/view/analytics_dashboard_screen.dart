import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/features/analytics/bloc/analytics_bloc.dart';
import 'package:mynix_frontend/features/analytics/bloc/analytics_event.dart';
import 'package:mynix_frontend/features/analytics/bloc/analytics_state.dart';
import 'package:mynix_frontend/features/analytics/repository/analytics_repository.dart';
import 'widgets/dashboard_metric_card.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mynix_frontend/features/analytics/models/analytics_models.dart';
import 'package:mynix_frontend/features/analytics/view/tabs/order_history_tab.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  String _selectedPeriod = 'today';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnalyticsBloc(AnalyticsRepository(apiClient.dio))
        ..add(LoadAnalytics(period: _selectedPeriod)),
      child: _AnalyticsDashboardView(
        selectedPeriod: _selectedPeriod,
        onPeriodChanged: (period) {
          setState(() {
            _selectedPeriod = period;
            _startDate = null;
            _endDate = null;
          });
        },
      ),
    );
  }
}

class _AnalyticsDashboardView extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const _AnalyticsDashboardView({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Filter Bar
          Container(
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
                          width: 300,
                          child: TabBar(
                            labelColor: AppColors.brandPrimary,
                            unselectedLabelColor: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                            indicatorColor: AppColors.brandPrimary,
                            tabs: const [
                              Tab(text: 'Дашборд'),
                              Tab(text: 'История заказов'),
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
                              startDate: (context.findAncestorStateOfType<_AnalyticsDashboardScreenState>() as _AnalyticsDashboardScreenState)._startDate,
                              endDate: (context.findAncestorStateOfType<_AnalyticsDashboardScreenState>() as _AnalyticsDashboardScreenState)._endDate,
                            )
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
                                startDate: (context.findAncestorStateOfType<_AnalyticsDashboardScreenState>() as _AnalyticsDashboardScreenState)._startDate,
                                endDate: (context.findAncestorStateOfType<_AnalyticsDashboardScreenState>() as _AnalyticsDashboardScreenState)._endDate,
                              )
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        ),
        
        // Content
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(), // Optional: disable swipe to avoid conflict with charts
            children: [
              // Tab 1: Dashboard
              BlocBuilder<AnalyticsBloc, AnalyticsState>(
                builder: (context, state) {
                  if (state is AnalyticsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is AnalyticsError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: TextStyle(color: AppColors.danger),
                      ),
                    );
                  }

                  if (state is AnalyticsLoaded) {
                    final metrics = state.metrics;
                    final xray = state.xray;

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<AnalyticsBloc>().add(
                      LoadAnalytics(
                        period: selectedPeriod,
                        startDate: (context.findAncestorStateOfType<_AnalyticsDashboardScreenState>() as _AnalyticsDashboardScreenState)._startDate,
                        endDate: (context.findAncestorStateOfType<_AnalyticsDashboardScreenState>() as _AnalyticsDashboardScreenState)._endDate,
                      )
                    );
                  },
                  color: AppColors.brandPrimary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(isDesktop ? 24 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // KPI Cards
                        if (isDesktop)
                          Row(
                            children: [
                              Expanded(
                                child: DashboardMetricCard(
                                  title: 'Выручка',
                                  value: '${metrics.totalRevenue.toStringAsFixed(0)} ${context.watch<SettingsBloc>().state.currency}',
                                  icon: PhosphorIconsRegular.wallet,
                                  gradientColors: [AppColors.brandPrimary, AppColors.brandSecondary],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DashboardMetricCard(
                                  title: 'Чистая прибыль',
                                  value: '${metrics.netProfit.toStringAsFixed(0)} ${context.watch<SettingsBloc>().state.currency}',
                                  icon: PhosphorIconsRegular.money,
                                  gradientColors: [AppColors.success, const Color(0xFF34D399)],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DashboardMetricCard(
                                  title: 'Маржинальность',
                                  value: '${metrics.marginPercentage.toStringAsFixed(1)}%',
                                  icon: PhosphorIconsRegular.chartLineUp,
                                  gradientColors: const [Color(0xFF8B5CF6), Color(0xFFC084FC)],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DashboardMetricCard(
                                  title: 'Количество чеков',
                                  value: '${metrics.totalOrders}',
                                  icon: PhosphorIconsRegular.receipt,
                                  gradientColors: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DashboardMetricCard(
                                      title: 'Выручка',
                                      value: '${metrics.totalRevenue.toStringAsFixed(0)} ${context.watch<SettingsBloc>().state.currency}',
                                      icon: PhosphorIconsRegular.wallet,
                                      gradientColors: [AppColors.brandPrimary, AppColors.brandSecondary],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DashboardMetricCard(
                                      title: 'Чистая прибыль',
                                      value: '${metrics.netProfit.toStringAsFixed(0)} ${context.watch<SettingsBloc>().state.currency}',
                                      icon: PhosphorIconsRegular.money,
                                      gradientColors: [AppColors.success, const Color(0xFF34D399)],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: DashboardMetricCard(
                                      title: 'Маржинальность',
                                      value: '${metrics.marginPercentage.toStringAsFixed(1)}%',
                                      icon: PhosphorIconsRegular.chartLineUp,
                                      gradientColors: const [Color(0xFF8B5CF6), Color(0xFFC084FC)],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DashboardMetricCard(
                                      title: 'Количество чеков',
                                      value: '${metrics.totalOrders}',
                                      icon: PhosphorIconsRegular.receipt,
                                      gradientColors: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        
                        // Charts Row
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildRevenueChart(context, metrics.timeSeries),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: _buildCategoryPieChart(context, xray.categories),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildRevenueChart(context, metrics.timeSeries),
                              const SizedBox(height: 24),
                              _buildCategoryPieChart(context, xray.categories),
                            ],
                          ),
                        const SizedBox(height: 24),

                        // XRay Table
                        _buildXRayTable(context, xray.items),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
          
          // Tab 2: Order History
          OrderHistoryTab(
            period: selectedPeriod,
            startDate: (context.findAncestorStateOfType<_AnalyticsDashboardScreenState>() as _AnalyticsDashboardScreenState)._startDate,
            endDate: (context.findAncestorStateOfType<_AnalyticsDashboardScreenState>() as _AnalyticsDashboardScreenState)._endDate,
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        final state = context.findAncestorStateOfType<_AnalyticsDashboardScreenState>() as _AnalyticsDashboardScreenState;
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: state._startDate != null && state._endDate != null
              ? DateTimeRange(start: state._startDate!, end: state._endDate!)
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
          onPeriodChanged('custom');
          // ignore: invalid_use_of_protected_member
          state.setState(() {
            state._startDate = picked.start;
            state._endDate = picked.end;
          });
          if (context.mounted) {
            context.read<AnalyticsBloc>().add(LoadAnalytics(period: 'custom', startDate: picked.start, endDate: picked.end));
          }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIconsRegular.calendar,
              size: 16,
              color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
            ),
            const SizedBox(width: 4),
            Text(
              'Период',
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context, List<TimeSeriesPoint> timeSeries) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      height: isDesktop ? 400 : 320,
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Динамика выручки',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: timeSeries.isEmpty
                ? Center(child: Text('Нет данных за период', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: isDark ? Colors.white10 : Colors.black12,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < timeSeries.length) {
                                // Just show some points to avoid clutter
                                if (timeSeries.length > 10 && value.toInt() % (timeSeries.length ~/ 5) != 0) {
                                  return const SizedBox.shrink();
                                }
                                // Simplistic parsing
                                String label = timeSeries[value.toInt()].timestamp;
                                if (label.contains(' ')) {
                                  // format "YYYY-MM-DD HH:00" -> "HH:00"
                                  label = label.split(' ')[1];
                                } else if (label.length == 10) {
                                  // format "YYYY-MM-DD" -> "DD.MM"
                                  final parts = label.split('-');
                                  label = '${parts[2]}.${parts[1]}';
                                } else if (label.length == 7) {
                                  // format "YYYY-MM" -> "MM.YYYY"
                                  final parts = label.split('-');
                                  label = '${parts[1]}.${parts[0]}';
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: isDark ? Colors.white54 : Colors.black54,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _getInterval(timeSeries),
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  _formatCompact(value),
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: timeSeries.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.revenue);
                          }).toList(),
                          isCurved: true,
                          color: AppColors.brandPrimary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.brandPrimary.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _getInterval(List<TimeSeriesPoint> data) {
    if (data.isEmpty) return 1000;
    double max = data.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
    if (max == 0) return 1000;
    return max / 4;
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildCategoryPieChart(BuildContext context, List<CategorySales> categories) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Color> colors = [
      AppColors.brandPrimary,
      const Color(0xFF34D399),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF3B82F6),
    ];

    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      height: isDesktop ? 400 : null,
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Продажи по категориям',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 24),
          if (isDesktop)
            Expanded(
              child: categories.isEmpty
                  ? Center(child: Text('Нет данных', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)))
                  : Row(
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: categories.asMap().entries.map((e) {
                                  final index = e.key;
                                  final item = e.value;
                                  return PieChartSectionData(
                                    color: colors[index % colors.length],
                                    value: item.percentage,
                                    title: '${item.percentage.toStringAsFixed(0)}%',
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Legend
                          Expanded(
                            child: Center(
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: categories.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = categories[index];
                                  return Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: colors[index % colors.length],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item.categoryName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? AppColors.darkText : AppColors.lightText,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${item.percentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white54 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
            )
          else
            categories.isEmpty
                ? Center(child: Text('Нет данных', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)))
                : Column(
                    children: [
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: categories.asMap().entries.map((e) {
                                  final index = e.key;
                                  final item = e.value;
                                  return PieChartSectionData(
                                    color: colors[index % colors.length],
                                    value: item.percentage,
                                    title: '${item.percentage.toStringAsFixed(0)}%',
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Legend
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: categories.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = categories[index];
                              return Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: colors[index % colors.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.categoryName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppColors.darkText : AppColors.lightText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${item.percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
        ],
      ),
    );
  }

  Widget _buildXRayTable(BuildContext context, List<XRayItem> items) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Рентген продаж (Позиции)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              Icon(PhosphorIconsRegular.chartLine, color: AppColors.brandPrimary),
            ],
          ),
          const SizedBox(height: 24),
          if (items.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Нет продаж за выбранный период', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
            ))
          else if (isDesktop)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 100),
                child: DataTable(
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('НАЗВАНИЕ И ЦЕНА')),
                    DataColumn(label: Text('ОПЦИИ')),
                    DataColumn(label: Text('КАТЕГОРИЯ')),
                    DataColumn(label: Text('КОЛИЧЕСТВО'), numeric: true),
                    DataColumn(label: Text('ВЫРУЧКА'), numeric: true),
                  ],
                  rows: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final price = item.quantity > 0 ? (item.revenue / item.quantity).toStringAsFixed(0) : '0';
                    final currency = context.read<SettingsBloc>().state.currency;

                    return DataRow(
                      cells: [
                        DataCell(Text(
                          '${index + 1}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                        )),
                        DataCell(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                            ),
                            Text(
                              '$price $currency',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        )),
                        DataCell(Text(
                          item.options ?? '-',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        )),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(item.category),
                        )),
                        DataCell(Text('${item.quantity} шт.')),
                        DataCell(Text(
                          '${item.revenue.toStringAsFixed(0)} $currency',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              itemBuilder: (context, index) {
                final item = items[index];
                final price = item.quantity > 0 ? (item.revenue / item.quantity).toStringAsFixed(0) : '0';
                final currency = context.read<SettingsBloc>().state.currency;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      // Rank
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.lightText),
                            ),
                            if (item.options != null && item.options!.isNotEmpty && item.options != '-')
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(item.options!, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              '$price $currency',
                              style: TextStyle(fontSize: 12, color: AppColors.brandPrimary),
                            ),
                          ],
                        ),
                      ),
                      // Sales
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.revenue.toStringAsFixed(0)} $currency',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.quantity} шт.',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
