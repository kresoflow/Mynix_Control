import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/widgets/app_text_field.dart';
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
  String _searchQuery = '';
  String _filterType = 'all'; // all, active, closed, diff

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

  List<Map<String, dynamic>> get _filteredHistory {
    return _history.where((s) {
      final shiftId = '${s['id']}';
      final openedBy = (s['opened_by_name'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase().trim();

      if (query.isNotEmpty && !shiftId.contains(query) && !openedBy.contains(query)) {
        return false;
      }

      final isOpen = s['is_open'] == true;
      final diff = (s['discrepancy'] as num?)?.toDouble() ?? 0.0;

      if (_filterType == 'active' && !isOpen) return false;
      if (_filterType == 'closed' && isOpen) return false;
      if (_filterType == 'diff' && (isOpen || diff == 0.0)) return false;

      return true;
    }).toList();
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

    double totalRevenue = 0;
    double totalDiscrepancy = 0;
    int activeCount = 0;
    int closedCount = 0;
    int diffCount = 0;

    for (final s in _history) {
      totalRevenue += (s['total_revenue'] as num?)?.toDouble() ?? 0.0;
      final diff = (s['discrepancy'] as num?)?.toDouble() ?? 0.0;
      totalDiscrepancy += diff;
      if (s['is_open'] == true) {
        activeCount++;
      } else {
        closedCount++;
        if (diff != 0.0) diffCount++;
      }
    }

    final filtered = _filteredHistory;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
              const SizedBox(width: 14),
              Expanded(
                child: AnalyticsKpiCard(
                  title: 'Суммарная выручка',
                  value: totalRevenue.toCurrency(context),
                  icon: PhosphorIconsRegular.chartLineUp,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 14),
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
          const SizedBox(height: 16),

          // ── Search & Filter Bar (CRM Style) ─────────────────────────
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  hintText: 'Поиск по номеру смены или кассиру...',
                  isCompact: true,
                  prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 16),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              _buildFilterChip('all', 'Все (${_history.length})', isDark),
              const SizedBox(width: 6),
              _buildFilterChip('active', 'Активные ($activeCount)', isDark, icon: PhosphorIconsRegular.radioactive),
              const SizedBox(width: 6),
              _buildFilterChip('closed', 'Закрытые ($closedCount)', isDark, icon: PhosphorIconsRegular.lockSimple),
              const SizedBox(width: 6),
              _buildFilterChip('diff', 'С расхождением ($diffCount)', isDark, icon: PhosphorIconsRegular.warningCircle),
            ],
          ),
          const SizedBox(height: 14),

          // ── Table Column Headers (CRM Style) ────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 52), // Space for avatar badge
                Expanded(flex: 3, child: _buildHeaderLabel('СМЕНА / КАССИР', isDark)),
                Expanded(flex: 2, child: _buildHeaderLabel('РАЗМЕН / ПРОДАЖИ', isDark)),
                Expanded(flex: 2, child: _buildHeaderLabel('ВЫРУЧКА', isDark)),
                _buildHeaderLabel('РЕЗУЛЬТАТ КАССЫ', isDark),
                const SizedBox(width: 30), // Caret space
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ── Shifts List Cards ───────────────────────────────────────
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Text(
                'Смены не найдены',
                style: TextStyle(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) => AnalyticsShiftRow(shift: filtered[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label, bool isDark, {IconData? icon}) {
    final isSelected = _filterType == type;
    return InkWell(
      onTap: () => setState(() => _filterType = type),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderLabel(String label, bool isDark) {
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
      ),
    );
  }
}
