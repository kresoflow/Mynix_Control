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
import 'widgets/revenue_share_widget.dart';
import 'widgets/low_stock_alerts_widget.dart';
import 'widgets/top_items_widget.dart';
import 'widgets/recent_orders_widget.dart';
import 'package:mynix_frontend/core/network/api_client.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AnalyticsBloc(AnalyticsRepository(apiClient.dio))
            ..add(LoadDashboardToday()),
      child: const _AnalyticsDashboardView(),
    );
  }
}

class _AnalyticsDashboardView extends StatelessWidget {
  const _AnalyticsDashboardView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text(
          'Аналитика',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(PhosphorIconsRegular.arrowsClockwise),
            tooltip: 'Обновить',
            onPressed: () {
              context.read<AnalyticsBloc>().add(LoadDashboardToday());
            },
          ),
        ],
      ),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsLoading) {
            return const _DashboardSkeleton();
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
            final data = state.data;
            final isDesktop = MediaQuery.of(context).size.width > 800;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<AnalyticsBloc>().add(LoadDashboardToday());
              },
              color: AppColors.brandPrimary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DashboardMetricCard(
                            title: 'Выручка за сегодня',
                            value: '${data.totalRevenue.toStringAsFixed(0)} ${context.watch<SettingsBloc>().state.currency}',
                            icon: PhosphorIconsRegular.wallet,
                            gradientColors: [AppColors.brandPrimary, AppColors.brandSecondary],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DashboardMetricCard(
                            title: 'Количество чеков',
                            value: '${data.totalOrders}',
                            icon: PhosphorIconsRegular.receipt,
                            gradientColors: const [Color(0xFF8B5CF6), Color(0xFFC084FC)], // Beautiful vibrant purple
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                TopItemsWidget(topItems: data.topItems),
                                const SizedBox(height: 24),
                                LowStockAlertsWidget(alerts: data.lowStockAlerts),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                RevenueShareWidget(
                                  dishesRevenue: data.dishesRevenue,
                                  retailRevenue: data.retailRevenue,
                                  totalRevenue: data.totalRevenue,
                                ),
                                const SizedBox(height: 24),
                                RecentOrdersWidget(orders: data.recentOrders),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          RevenueShareWidget(
                            dishesRevenue: data.dishesRevenue,
                            retailRevenue: data.retailRevenue,
                            totalRevenue: data.totalRevenue,
                          ),
                          const SizedBox(height: 24),
                          TopItemsWidget(topItems: data.topItems),
                          const SizedBox(height: 24),
                          RecentOrdersWidget(orders: data.recentOrders),
                          const SizedBox(height: 24),
                          LowStockAlertsWidget(alerts: data.lowStockAlerts),
                        ],
                      ),
                    const SizedBox(height: 24), // Extra bottom padding
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DashboardSkeleton extends StatefulWidget {
  const _DashboardSkeleton();

  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkCard : AppColors.lightBorder;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + (_controller.value * 0.5),
          child: child,
        );
      },
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _buildSkeletonBox(140, baseColor)),
                const SizedBox(width: 16),
                Expanded(child: _buildSkeletonBox(140, baseColor)),
              ],
            ),
            const SizedBox(height: 24),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildSkeletonBox(200, baseColor),
                        const SizedBox(height: 24),
                        _buildSkeletonBox(300, baseColor),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildSkeletonBox(250, baseColor),
                        const SizedBox(height: 24),
                        _buildSkeletonBox(200, baseColor),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildSkeletonBox(200, baseColor),
                  const SizedBox(height: 24),
                  _buildSkeletonBox(250, baseColor),
                  const SizedBox(height: 24),
                  _buildSkeletonBox(300, baseColor),
                  const SizedBox(height: 24),
                  _buildSkeletonBox(200, baseColor),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonBox(double height, Color color) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
