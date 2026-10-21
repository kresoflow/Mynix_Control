// ==============================================================================
// МОДУЛЬ: Аналитика / Главный экран дашборда (AnalyticsDashboardScreen)
// ДОМЕН: lib/features/analytics/view/analytics_dashboard_screen.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/analytics/bloc/analytics_bloc.dart';
import 'package:kreso_frontend/features/analytics/bloc/analytics_event.dart';
import 'package:kreso_frontend/features/analytics/bloc/analytics_state.dart';
import 'tabs/dashboard_summary_tab.dart';
import 'tabs/order_history_tab.dart';
import 'tabs/shift_history_analytics_tab.dart';
import 'widgets/analytics_filter_bar.dart';

// ── Главный контейнер экрана аналитики ───────────────────────────────────────
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
  void initState() {
    super.initState();
    // [ИНВАРИАНТ] При первом открытии запрашиваем данные за сегодня, если они еще не загружены.
    // Если BLoC уже держит данные в памяти, экран отобразит их мгновенно без спиннеров.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<AnalyticsBloc>();
      if (bloc.state is AnalyticsInitial) {
        bloc.add(const LoadAnalytics(period: 'today'));
      } else if (bloc.state is AnalyticsLoaded) {
        final loaded = bloc.state as AnalyticsLoaded;
        setState(() {
          _selectedPeriod = loaded.period;
          _startDate = loaded.startDate;
          _endDate = loaded.endDate;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
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
              context.read<AnalyticsBloc>().add(LoadAnalytics(period: period));
            },
            onCustomDateSelected: (start, end) {
              setState(() {
                _selectedPeriod = 'custom';
                _startDate = start;
                _endDate = end;
              });
              context.read<AnalyticsBloc>().add(
                    LoadAnalytics(
                      period: 'custom',
                      startDate: start,
                      endDate: end,
                    ),
                  );
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
    );
  }
}
