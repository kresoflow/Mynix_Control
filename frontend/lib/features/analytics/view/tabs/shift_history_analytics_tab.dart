// ==============================================================================
// МОДУЛЬ: Аналитика / Вкладка истории кассовых смен (Shift History)
// ДОМЕН: lib/features/analytics/view/tabs/shift_history_analytics_tab.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/pos/repository/shift_repository.dart';
import '../widgets/shift_history_kpi_cards.dart';
import '../widgets/shift_history_table.dart';

/// Вкладка аналитики и журнала кассовых смен
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
  String _filterType = 'all';
  String _sortColumn = 'id';
  bool _sortAscending = false;

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

  void _toggleSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = false;
      }
    });
  }

  List<Map<String, dynamic>> get _filteredHistory {
    final list = _history.where((s) {
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

    list.sort((a, b) {
      int cmp = 0;
      if (_sortColumn == 'id') {
        final idA = (a['id'] as num?)?.toInt() ?? 0;
        final idB = (b['id'] as num?)?.toInt() ?? 0;
        cmp = idA.compareTo(idB);
      } else if (_sortColumn == 'revenue') {
        final revA = (a['total_revenue'] as num?)?.toDouble() ?? 0.0;
        final revB = (b['total_revenue'] as num?)?.toDouble() ?? 0.0;
        cmp = revA.compareTo(revB);
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
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
            AppButton.secondary(
              onPressed: _loadHistory,
              icon: PhosphorIconsRegular.arrowClockwise,
              label: 'Повторить',
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
          ShiftHistoryKpiCards(
            totalCount: _history.length,
            totalRevenue: totalRevenue,
            totalDiscrepancy: totalDiscrepancy,
          ),
          const SizedBox(height: 16),

          // ── Search & Filter Bar (UI Kit Style) ──────────────────────
          Row(
            children: [
              Expanded(
                child: AppSearchField(
                  size: AppSearchFieldSize.md,
                  hintText: 'Поиск по номеру смены или кассиру...',
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              AppFilterBar(
                spacing: 6.0,
                children: [
                  AppFilterChip(
                    label: 'Все',
                    count: _history.length,
                    isSelected: _filterType == 'all',
                    onTap: () => setState(() => _filterType = 'all'),
                  ),
                  AppFilterChip(
                    label: 'Активные',
                    count: activeCount,
                    icon: PhosphorIconsRegular.radioactive,
                    isSelected: _filterType == 'active',
                    onTap: () => setState(() => _filterType = 'active'),
                  ),
                  AppFilterChip(
                    label: 'Закрытые',
                    count: closedCount,
                    icon: PhosphorIconsRegular.lockSimple,
                    isSelected: _filterType == 'closed',
                    onTap: () => setState(() => _filterType = 'closed'),
                  ),
                  AppFilterChip(
                    label: 'С расхождением',
                    count: diffCount,
                    icon: PhosphorIconsRegular.warningCircle,
                    isSelected: _filterType == 'diff',
                    activeColor: AppColors.warning,
                    onTap: () => setState(() => _filterType = 'diff'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Unified Data Table (AppDataTableHeader + AppDataTableRow) ──
          ShiftHistoryTable(
            shifts: filtered,
            sortColumn: _sortColumn,
            sortAscending: _sortAscending,
            onToggleSort: _toggleSort,
          ),
        ],
      ),
    );
  }
}
