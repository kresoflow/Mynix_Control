import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/features/pos/repository/shift_repository.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_event.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_state.dart';

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
  
  // Privacy toggle (blind close / hide cash)
  bool _hideCashAmount = false;
  bool _showDiscrepancyHint = false;

  final _cashInputController = TextEditingController();
  double _actualCash = 0;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _shiftRepository = ShiftRepository(apiClient.dio);
    _loadReport();

    _cashInputController.addListener(() {
      final val = double.tryParse(_cashInputController.text.replaceAll(',', '.')) ?? 0;
      setState(() => _actualCash = val);
    });
  }

  @override
  void dispose() {
    _cashInputController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ShiftBloc, ShiftState>(
      builder: (context, shiftState) {
        double expectedCash = 0.0;
        String openedAtStr = '-';

        if (shiftState is ShiftOpen) {
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
          width: 480,
          actions: const [],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Sub-info ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('Смена открыта ($openedAtStr)', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                    ],
                  ),
                  IconButton(
                    icon: Icon(_hideCashAmount ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye, size: 16),
                    tooltip: _hideCashAmount ? 'Показать суммы' : 'Скрыть суммы (Режим приватности)',
                    onPressed: () => setState(() => _hideCashAmount = !_hideCashAmount),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Tab Switcher ─────────────────────────────────────────────
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
                      child: _buildTabButton(0, 'X-Отчет (Сводка)', PhosphorIconsRegular.chartPie, isDark),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildTabButton(1, 'Закрытие смены', PhosphorIconsRegular.lockKey, isDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Tab 0: X-Report Summary ──────────────────────────────────
              if (_selectedTab == 0)
                _buildXReportTab(context, expectedCash, isDark)
              // ── Tab 1: Close Shift ───────────────────────────────────────
              else
                _buildCloseShiftTab(context, expectedCash, isDark),
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
            Icon(icon, size: 15, color: isSelected ? Colors.black : (isDark ? AppColors.darkText : AppColors.lightText)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.black : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXReportTab(BuildContext context, double expectedCash, bool isDark) {
    if (_isLoadingReport) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_reportError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text('Ошибка загрузки: $_reportError', style: const TextStyle(color: AppColors.danger)),
      );
    }

    final openingCash = (num.tryParse(_report?['opening_cash']?.toString() ?? '0') ?? 0).toDouble();
    final cashSales = (num.tryParse(_report?['cash_sales']?.toString() ?? '0') ?? 0).toDouble();
    final transferSales = (num.tryParse(_report?['transfer_sales']?.toString() ?? '0') ?? 0).toDouble();
    final totalRevenue = (num.tryParse(_report?['total_revenue']?.toString() ?? '0') ?? 0).toDouble();
    final ordersCount = _report?['orders_count'] ?? 0;
    final avgCheck = (num.tryParse(_report?['average_check']?.toString() ?? '0') ?? 0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatRow('Кассовый остаток на начало', openingCash, isDark),
        const SizedBox(height: 10),

        // Revenue Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            children: [
              _buildIconStatRow(PhosphorIconsRegular.money, 'Выручка (Наличные)', cashSales, isDark),
              const SizedBox(height: 6),
              _buildIconStatRow(PhosphorIconsRegular.qrCode, 'Выручка (Переводы)', transferSales, isDark),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Divider(height: 1),
              ),
              _buildIconStatRow(PhosphorIconsRegular.chartLineUp, 'ИТОГО ВЫРУЧКА', totalRevenue, isDark, isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Orders & Avg Check
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Всего чеков: $ordersCount шт.', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
            Text('Средний чек: ${_hideCashAmount ? '••••' : avgCheck.toCurrency(context)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText)),
          ],
        ),
        const SizedBox(height: 14),

        // Expected Cash Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ожидается в кассе (Нал):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText)),
              Text(
                _hideCashAmount ? '•••• с' : expectedCash.toCurrency(context),
                style: AppTextStyles.h2.copyWith(color: AppColors.brandPrimary, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        AppButton.secondary(
          label: 'Закрыть',
          isFullWidth: true,
          height: 44,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildCloseShiftTab(BuildContext context, double expectedCash, bool isDark) {
    final diff = _actualCash - expectedCash;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Пересчитайте наличные в кассовом ящике:',
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        TextField(
          controller: _cashInputController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: AppTextStyles.h1.copyWith(fontWeight: FontWeight.w900, fontSize: 24),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixIcon: const Icon(PhosphorIconsRegular.money, size: 22),
            suffixText: 'сомони',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        // Blind count hint toggle
        InkWell(
          onTap: () => setState(() => _showDiscrepancyHint = !_showDiscrepancyHint),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_showDiscrepancyHint ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash, size: 14, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  const SizedBox(width: 6),
                  Text(
                    _showDiscrepancyHint ? 'Скрыть подсказку' : 'Показать ожидаемую сумму',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  ),
                ],
              ),
              if (_showDiscrepancyHint)
                Text(
                  expectedCash.toCurrency(context),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
                ),
            ],
          ),
        ),

        if (_showDiscrepancyHint) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: diff == 0
                  ? AppColors.success.withValues(alpha: 0.1)
                  : (diff < 0 ? AppColors.danger.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  diff == 0 ? '✓ Сходится точно' : (diff < 0 ? 'Недостача:' : 'Излишек:'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
                  ),
                ),
                Text(
                  diff.abs().toCurrency(context),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        AppButton.danger(
          label: 'Подтвердить и закрыть смену',
          icon: PhosphorIconsRegular.lockKey,
          isFullWidth: true,
          height: 48,
          onPressed: () {
            context.read<ShiftBloc>().add(CloseShiftRequested(_actualCash));
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, double value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
        Text(_hideCashAmount ? '••••' : value.toCurrency(context), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkText : AppColors.lightText)),
      ],
    );
  }

  Widget _buildIconStatRow(IconData icon, String label, double value, bool isDark, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: isBold ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                color: isBold ? (isDark ? AppColors.darkText : AppColors.lightText) : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
          ],
        ),
        Text(
          _hideCashAmount ? '••••' : value.toCurrency(context),
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: isBold ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
          ),
        ),
      ],
    );
  }
}
