import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/features/analytics/bloc/analytics_bloc.dart';
import 'package:mynix_frontend/features/analytics/bloc/analytics_event.dart';
import 'package:mynix_frontend/features/analytics/repository/analytics_repository.dart';
import 'tabs/dashboard_summary_tab.dart';
import 'tabs/order_history_tab.dart';
import 'tabs/shift_history_analytics_tab.dart';
import 'widgets/analytics_filter_bar.dart';

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
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            AnalyticsFilterBar(
              selectedPeriod: _selectedPeriod,
              startDate: _startDate,
              endDate: _endDate,
              onPeriodChanged: (period) {
                setState(() {
                  _selectedPeriod = period;
                  _startDate = null;
                  _endDate = null;
                });
              },
              onCustomDateSelected: (start, end) {
                setState(() {
                  _selectedPeriod = 'custom';
                  _startDate = start;
                  _endDate = end;
                });
              },
            ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  DashboardSummaryTab(
                    selectedPeriod: _selectedPeriod,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  OrderHistoryTab(
                    period: _selectedPeriod,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  ShiftHistoryAnalyticsTab(
                    period: _selectedPeriod,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
