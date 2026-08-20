import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/features/pos/repository/shift_repository.dart';

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
  late final ShiftRepository _shiftRepository;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _shiftRepository = ShiftRepository(apiClient.dio);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _shiftRepository.getShiftsHistory();
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
    int totalOrders = 0;

    for (final s in _history) {
      totalRevenue += (s['total_revenue'] as num?)?.toDouble() ?? 0.0;
      totalDiscrepancy += (s['discrepancy'] as num?)?.toDouble() ?? 0.0;
      totalOrders += (s['orders_count'] as num?)?.toInt() ?? 0;
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
                child: _buildSummaryCard(
                  title: 'Всего смен в журнале',
                  value: '${_history.length}',
                  icon: PhosphorIconsRegular.clockCounterClockwise,
                  color: AppColors.brandPrimary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Суммарная выручка',
                  value: totalRevenue.toCurrency(context),
                  icon: PhosphorIconsRegular.chartLineUp,
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Чистое расхождение кассы',
                  value: totalDiscrepancy == 0
                      ? '0 с (Точно)'
                      : (totalDiscrepancy < 0 ? '${totalDiscrepancy.toCurrency(context)}' : '+${totalDiscrepancy.toCurrency(context)}'),
                  icon: PhosphorIconsRegular.scales,
                  color: totalDiscrepancy == 0 ? AppColors.success : (totalDiscrepancy < 0 ? AppColors.danger : AppColors.warning),
                  isDark: isDark,
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
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              itemBuilder: (context, index) {
                final shift = _history[index];
                return _buildShiftRow(context, shift, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.lightText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftRow(BuildContext context, Map<String, dynamic> shift, bool isDark) {
    final shiftId = shift['id'];
    final isOpen = shift['is_open'] == true;
    final totalRev = (shift['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final diff = (shift['discrepancy'] as num?)?.toDouble();
    final openingCash = (shift['opening_cash'] as num?)?.toDouble() ?? 0.0;
    final ordersCount = shift['orders_count'] ?? 0;

    String openedStr = '-';
    if (shift['opened_at'] != null) {
      final p = DateTime.tryParse(shift['opened_at'].toString());
      if (p != null) openedStr = DateFormat('dd.MM.yyyy, HH:mm').format(p.toLocal());
    }

    String closedStr = '-';
    if (shift['closed_at'] != null) {
      final p = DateTime.tryParse(shift['closed_at'].toString());
      if (p != null) closedStr = DateFormat('HH:mm').format(p.toLocal());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isOpen ? AppColors.success.withValues(alpha: 0.12) : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isOpen ? AppColors.success.withValues(alpha: 0.3) : Colors.transparent),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$shiftId',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isOpen ? AppColors.success : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOpen ? AppColors.success : AppColors.darkSubtext,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOpen ? 'Смена активна' : 'Смена закрыта',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isOpen ? AppColors.success : (isDark ? AppColors.darkText : AppColors.lightText)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isOpen ? 'Открыта: $openedStr' : 'Открыта: $openedStr  →  Закрыта: $closedStr',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Размен / Чеков:', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                const SizedBox(height: 2),
                Text('${openingCash.toCurrency(context)} • $ordersCount шт.', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Выручка смены:', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                const SizedBox(height: 2),
                Text(totalRev.toCurrency(context), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.brandPrimary)),
              ],
            ),
          ),
          if (!isOpen && diff != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: diff == 0
                    ? AppColors.success.withValues(alpha: 0.1)
                    : (diff < 0 ? AppColors.danger.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
                ),
              ),
              child: Text(
                diff == 0 ? '✓ Точно (0 с)' : (diff < 0 ? 'Недостача: ${diff.toCurrency(context)}' : 'Излишек: +${diff.toCurrency(context)}'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
