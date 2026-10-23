// ==============================================================================
// МОДУЛЬ: POS / Хаб управления сменой (PosShiftHubModal)
// ДОМЕН: lib/features/pos/view/widgets/pos_shift_hub_modal.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Модальное окно управления кассовой сменой:
// 1. Вкладки: X-отчет, Z-отчет (закрытие смены), Журнал прошлых смен.
// 2. Поддержка слепого режима (Blind POS) с защитой финансовых сумм PIN-кодом.
// 3. Использует дизайн-токены AppRadii, AppColors, AppSpacing.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/network/api_client.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_spacing.dart';
import 'package:kreso_frontend/core/widgets/app_dialog_scaffold.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_event.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_state.dart';
import 'package:kreso_frontend/features/pos/repository/shift_repository.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';

import 'shift_hub/shift_x_report_tab.dart';
import 'shift_hub/shift_z_close_tab.dart';
import 'shift_hub/shift_history_tab.dart';
import 'shift_hub/shift_pin_dialog.dart';

// ── 1. Модальное окно хаба смены ──────────────────────────────────────────────

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
        String msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.contains('Not authenticated') || msg.contains('401')) {
          msg = 'Сессия истекла. Пожалуйста, выполните вход заново.';
        }
        setState(() {
          _reportError = msg;
          _isLoadingReport = false;
        });
      }
    }
  }

  Future<bool> _handleUnlockPin() async {
    final success = await showShiftPinDialog(context);
    if (success && mounted) {
      context.read<ShiftBloc>().add(const ToggleFinancialsVisibility(unlock: true));
      return true;
    }
    return false;
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
            if (parsed != null) openedAtStr = DateFormat('dd.MM, HH:mm').format(parsed.toLocal());
          }
        }

        return AppDialogScaffold(
          title: 'Управление сменой',
          icon: PhosphorIconsRegular.vault,
          maxWidth: 480,
          maxHeight: 450,
          actions: const [],
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusRow(isOpen, isUnlocked, openedAtStr, isDark),
                AppSpacing.vSm,
                _buildTabsBar(isDark),
                AppSpacing.vSm,
                Expanded(
                  child: IndexedStack(
                    sizing: StackFit.expand,
                    index: _selectedTab,
                    children: [
                      SingleChildScrollView(
                        child: ShiftXReportTab(
                          report: _report,
                          isLoading: _isLoadingReport,
                          error: _reportError,
                          hideAmounts: !isUnlocked,
                          expectedCash: expectedCash,
                          onUnlockPin: _handleUnlockPin,
                          onRefresh: _loadReport,
                        ),
                      ),
                      SingleChildScrollView(
                        child: ShiftZCloseTab(
                          expectedCash: expectedCash,
                          onUnlockPin: _handleUnlockPin,
                          isPinUnlocked: isUnlocked,
                        ),
                      ),
                      ShiftHistoryTab(
                        isActive: _selectedTab == 2,
                        hideAmounts: !isUnlocked,
                        onUnlockPin: _handleUnlockPin,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(bool isOpen, bool isUnlocked, String openedAtStr, bool isDark) {
    final isBlindMode = context.watch<SettingsBloc?>()?.state.blindPosEnabled ?? true;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: isOpen ? AppColors.success : AppColors.danger, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(isOpen ? 'Смена активна ($openedAtStr)' : 'Смена закрыта', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          ],
        ),
        if (isOpen)
          InkWell(
            onTap: !isBlindMode
                ? null
                : (isUnlocked
                    ? () => context.read<ShiftBloc>().add(const ToggleFinancialsVisibility(unlock: false))
                    : _handleUnlockPin),
            borderRadius: AppRadii.radiusXs,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isUnlocked ? AppColors.success : AppColors.brandPrimary).withValues(alpha: 0.1),
                borderRadius: AppRadii.radiusXs,
                border: Border.all(color: (isUnlocked ? AppColors.success : AppColors.brandPrimary).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUnlocked ? PhosphorIconsRegular.lockOpen : PhosphorIconsRegular.lockKey,
                    size: 12,
                    color: isUnlocked ? AppColors.success : AppColors.brandPrimary,
                  ),
                  AppSpacing.hXxs,
                  Text(
                    !isBlindMode
                        ? 'Суммы открыты'
                        : (isUnlocked ? 'Скрыть суммы' : 'Разблокировать (PIN)'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isUnlocked ? AppColors.success : AppColors.brandPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabsBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.radiusMd,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton(0, 'X-Отчет', PhosphorIconsRegular.chartPie, isDark)),
          AppSpacing.hXxs,
          Expanded(child: _buildTabButton(1, 'Z-Отчет', PhosphorIconsRegular.lockKey, isDark)),
          AppSpacing.hXxs,
          Expanded(child: _buildTabButton(2, 'Журнал', PhosphorIconsRegular.archive, isDark)),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon, bool isDark) {
    final isSelected = _selectedTab == index;
    final color = isSelected ? AppColors.white : (isDark ? AppColors.darkText : AppColors.lightText);
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: AppRadii.radiusSm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : AppColors.transparent,
          borderRadius: AppRadii.radiusSm,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            AppSpacing.hXxs,
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
