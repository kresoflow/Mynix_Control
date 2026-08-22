import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/features/pos/repository/shift_repository.dart';
import '../widgets/analytics_kpi_card.dart';
import '../widgets/analytics_shift_row.dart';

class ShiftHistoryAnalyticsTab extends StatefulWidget {
  final String? period;
  final DateTime? startDate;
  final DateTime? endDate;

  const ShiftHistoryAnalyticsTab({
    super.key,
    this.period,
    this.startDate,
    this.endDate,
  });

  @override
  State<ShiftHistoryAnalyticsTab> createState() => _ShiftHistoryAnalyticsTabState();
}

class _ShiftHistoryAnalyticsTabState extends State<ShiftHistoryAnalyticsTab> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = context.read<ShiftRepository>();
      final list = await repo.getShiftsHistory();
      if (mounted) {
        setState(() {
          _history = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ошибка: $_error', style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(PhosphorIconsRegular.arrowClockwise),
              label: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.vault, size: 48, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            const SizedBox(height: 12),
            Text(
              'История кассовых смен пуста',
              style: TextStyle(fontSize: 16, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
          ],
        ),
      );
    }

    // Aggregate statistics
    double totalRevenue = 0;
    double totalDiscrepancy = 0;

    for (final s in _history) {
      totalRevenue += (s['total_revenue'] as num?)?.toDouble() ?? 0.0;
      totalDiscrepancy += (s['discrepancy'] as num?)?.toDouble() ?? 0.0;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── KPI Summary Cards ───────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: AnalyticsKpiCard(
                  title: 'Всего смен в журнале',
                  value: '${_history.length}',
                  icon: PhosphorIconsRegular.clockCounterClockwise,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnalyticsKpiCard(
                  title: 'Суммарная выручка',
                  value: totalRevenue.toCurrency(context),
                  icon: PhosphorIconsRegular.chartLineUp,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnalyticsKpiCard(
                  title: 'Чистое расхождение кассы',
                  value: totalDiscrepancy == 0
                      ? '0 с (Точно)'
                      : (totalDiscrepancy < 0 ? totalDiscrepancy.toCurrency(context) : '+${totalDiscrepancy.toCurrency(context)}'),
                  icon: PhosphorIconsRegular.scales,
                  color: totalDiscrepancy == 0 ? AppColors.success : (totalDiscrepancy < 0 ? AppColors.danger : AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Shifts Table / List ─────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              itemBuilder: (context, index) {
                return AnalyticsShiftRow(shift: _history[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
