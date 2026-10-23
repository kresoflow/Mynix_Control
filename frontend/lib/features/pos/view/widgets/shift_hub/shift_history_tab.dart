// ==============================================================================
// МОДУЛЬ: Касса / Смены / Вкладка истории смен (ShiftHistoryTab)
// ДОМЕН: lib/features/pos/view/widgets/shift_hub/shift_history_tab.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/features/analytics/view/widgets/dialogs/shift_history_details_dialog.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_event.dart';
import 'package:kreso_frontend/features/pos/repository/shift_repository.dart';

class ShiftHistoryTab extends StatefulWidget {
  final bool isActive;
  final bool hideAmounts;
  final VoidCallback? onUnlockPin;

  const ShiftHistoryTab({
    super.key,
    this.isActive = true,
    this.hideAmounts = false,
    this.onUnlockPin,
  });

  @override
  State<ShiftHistoryTab> createState() => _ShiftHistoryTabState();
}

class _ShiftHistoryTabState extends State<ShiftHistoryTab> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  @override
  void didUpdateWidget(ShiftHistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive && _history.isEmpty && !_isLoading) {
      _loadHistory();
    }
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
      if (mounted) setState(() { _history = list; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.contains('Not authenticated') || msg.contains('401')) {
          msg = 'Сессия истекла. Пожалуйста, выполните вход заново.';
        }
        setState(() { _error = msg; _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) return Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
    if (_error != null) return _buildErrorState(context);
    if (_history.isEmpty) return _buildEmptyState(isDark);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Всего записей: ${_history.length}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
              InkWell(
                onTap: _loadHistory,
                borderRadius: AppRadii.radiusXs,
                child: Row(
                  children: [
                    Icon(PhosphorIconsRegular.arrowClockwise, size: 12, color: AppColors.brandPrimary),
                    const SizedBox(width: 4),
                    Text('Обновить', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) => _buildShiftCard(context, _history[index], isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final isAuth = _error!.contains('Сессия истекла') || _error!.contains('authenticated');
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(PhosphorIconsRegular.warningCircle, size: 28, color: AppColors.danger),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (isAuth)
              AppPrimaryButton(
                label: 'Войти заново',
                icon: PhosphorIconsRegular.signIn,
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  context.read<AuthBloc>().add(LoggedOut());
                },
              )
            else
              AppSecondaryButton(label: 'Повторить попытку', icon: PhosphorIconsRegular.arrowClockwise, onPressed: _loadHistory),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.archive, size: 36, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          const SizedBox(height: 8),
          Text('История смен пуста', style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          const SizedBox(height: 10),
          InkWell(
            onTap: _loadHistory,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsRegular.arrowClockwise, size: 14, color: AppColors.brandPrimary),
                const SizedBox(width: 4),
                Text('Обновить', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(BuildContext context, Map<String, dynamic> item, bool isDark) {
    final shiftId = item['id'];
    final isOpen = item['is_open'] == true;
    final totalRev = (item['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final cashRev = (item['cash_sales'] as num?)?.toDouble() ?? 0.0;
    final transferRev = (item['transfer_sales'] as num?)?.toDouble() ?? 0.0;
    final ordersCount = item['orders_count'] ?? 0;
    final diff = (item['discrepancy'] as num?)?.toDouble();
    final employee = item['opened_by_name']?.toString() ?? 'Кассир';

    final totalRevStr = widget.hideAmounts ? '••••' : totalRev.toCurrency(context);
    final cashRevStr = widget.hideAmounts ? '••••' : cashRev.toCurrency(context);
    final transferRevStr = widget.hideAmounts ? '••••' : transferRev.toCurrency(context);

    String openDate = '-';
    if (item['opened_at'] != null) {
      final p = DateTime.tryParse(item['opened_at'].toString());
      if (p != null) openDate = DateFormat('dd.MM HH:mm').format(p.toLocal());
    }

    String diffText = 'Точно';
    if (diff != null && diff != 0) {
      diffText = widget.hideAmounts ? '••••' : (diff < 0 ? diff.toCurrency(context) : '+${diff.toCurrency(context)}');
    }

    return InkWell(
      onTap: () {
        if (widget.hideAmounts && widget.onUnlockPin != null) {
          widget.onUnlockPin!();
          return;
        }
        ShiftHistoryDetailsDialog.show(context, item);
      },
      borderRadius: AppRadii.radiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: AppRadii.radiusMd,
          border: Border.all(
            color: isOpen ? AppColors.brandPrimary.withValues(alpha: 0.5) : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isOpen ? AppColors.success.withValues(alpha: 0.15) : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius: AppRadii.radiusSm,
              ),
              alignment: Alignment.center,
              child: Text(
                '#$shiftId',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isOpen ? AppColors.success : (isDark ? AppColors.darkText : AppColors.lightText)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isOpen ? 'Активна' : 'Закрыта',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isOpen ? AppColors.success : (isDark ? AppColors.darkText : AppColors.lightText)),
                      ),
                      const SizedBox(width: 6),
                      Text('$openDate • $employee', style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Выручка: $totalRevStr (Нал: $cashRevStr, Б/н: $transferRevStr) • $ordersCount чк.',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (!isOpen && diff != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: diff == 0 ? AppColors.success.withValues(alpha: 0.1) : (diff < 0 ? AppColors.danger.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1)),
                  borderRadius: AppRadii.radiusXs,
                ),
                child: Text(
                  diffText,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning)),
                ),
              ),
            const SizedBox(width: 2),
            Icon(PhosphorIconsRegular.caretRight, size: 14, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ],
        ),
      ),
    );
  }
}
