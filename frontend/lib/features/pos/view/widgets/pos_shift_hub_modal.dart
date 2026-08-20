import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/features/pos/repository/shift_repository.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_event.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_state.dart';

import 'shift_hub/shift_x_report_tab.dart';
import 'shift_hub/shift_z_close_tab.dart';
import 'shift_hub/shift_history_tab.dart';
import 'shift_hub/shift_pin_dialog.dart';

void showShiftHubModal(BuildContext context, {int initialTab = 0}) {
  showDialog(
    context: context,
    builder: (ctx) => PosShiftHubModal(initialTab: initialTab),
  );
}

class PosShiftHubModal extends StatefulWidget {
  final int initialTab;

  const PosShiftHubModal({super.key, this.initialTab = 0});

  @override
  State<PosShiftHubModal> createState() => _PosShiftHubModalState();
}

class _PosShiftHubModalState extends State<PosShiftHubModal> {
  late int _selectedTab;
  late final ShiftRepository _shiftRepository;
  bool _isLoadingReport = true;
  String? _reportError;
  Map<String, dynamic>? _report;
  
  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _shiftRepository = ShiftRepository(apiClient.dio);
    _loadReport();
  }

  Future<void> _loadReport() async {
    final shiftState = context.read<ShiftBloc>().state;
    if (shiftState is! ShiftOpen) {
      setState(() {
        _isLoadingReport = false;
        _report = null;
      });
      return;
    }

    setState(() {
      _isLoadingReport = true;
      _reportError = null;
    });
    try {
      final data = await _shiftRepository.getXReport();
      if (mounted) {
        setState(() {
          _report = data;
          _isLoadingReport = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reportError = e.toString();
          _isLoadingReport = false;
        });
      }
    }
  }

  Future<void> _handleUnlockPin() async {
    final success = await showShiftPinDialog(context);
    if (success && mounted) {
      context.read<ShiftBloc>().add(const ToggleFinancialsVisibility(unlock: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ShiftBloc, ShiftState>(
      builder: (context, shiftState) {
        final isOpen = shiftState is ShiftOpen;
        final isUnlocked = isOpen && shiftState.isFinancialsUnlocked;
        double expectedCash = 0.0;
        String openedAtStr = '-';

        if (isOpen) {
          final shift = shiftState.shiftDetails;
          expectedCash = (shift['current_cash_expected'] ?? shift['opening_cash'] as num?)?.toDouble() ?? 0.0;
          if (shift['opened_at'] != null) {
            final parsed = DateTime.tryParse(shift['opened_at'].toString());
            if (parsed != null) {
              openedAtStr = DateFormat('dd.MM, HH:mm').format(parsed.toLocal());
            }
          }
        }

        return MynixDialog(
          title: 'Управление сменой',
          icon: PhosphorIconsRegular.vault,
          width: 500,
          actions: const [],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Sub-info & Privacy Lock ────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOpen ? AppColors.success : AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOpen ? 'Смена активна ($openedAtStr)' : 'Смена закрыта',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      isUnlocked ? PhosphorIconsRegular.lockOpen : PhosphorIconsRegular.lockKey,
                      size: 16,
                      color: isUnlocked ? AppColors.success : AppColors.brandPrimary,
                    ),
                    tooltip: isUnlocked ? 'Скрыть суммы (Заблокировать)' : 'Разблокировать суммы (PIN)',
                    onPressed: isUnlocked
                        ? () => context.read<ShiftBloc>().add(const ToggleFinancialsVisibility(unlock: false))
                        : _handleUnlockPin,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── 3-Tab Switcher ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(0, 'X-Отчет', PhosphorIconsRegular.chartPie, isDark),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildTabButton(1, 'Z-Отчет', PhosphorIconsRegular.lockKey, isDark),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildTabButton(2, 'Журнал', PhosphorIconsRegular.archive, isDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Active Tab Content ───────────────────────────────────────
              if (_selectedTab == 0)
                ShiftXReportTab(
                  report: _report,
                  isLoading: _isLoadingReport,
                  error: _reportError,
                  hideAmounts: !isUnlocked,
                  expectedCash: expectedCash,
                  onUnlockPin: _handleUnlockPin,
                )
              else if (_selectedTab == 1)
                ShiftZCloseTab(
                  expectedCash: expectedCash,
                  onUnlockPin: _handleUnlockPin,
                  isPinUnlocked: isUnlocked,
                )
              else
                const ShiftHistoryTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon, bool isDark) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.black : (isDark ? AppColors.darkText : AppColors.lightText)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.black : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
