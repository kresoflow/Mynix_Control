// ==============================================================================
// МОДУЛЬ: Касса / Смены / Вкладка истории смен (ShiftHistoryTab)
// ДОМЕН: lib/features/pos/view/widgets/shift_hub/shift_history_tab.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_event.dart';
import 'package:kreso_frontend/features/pos/repository/shift_repository.dart';

class ShiftHistoryTab extends StatefulWidget {
  const ShiftHistoryTab({super.key});

  @override
  State<ShiftHistoryTab> createState() => _ShiftHistoryTabState();
}

class _ShiftHistoryTabState extends State<ShiftHistoryTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _history = [];

  @override
  bool get wantKeepAlive => true;

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
        String msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.contains('Not authenticated') || msg.contains('401')) {
          msg = 'Сессия истекла. Пожалуйста, выполните вход заново.';
        }
        setState(() {
          _error = msg;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
    }

    if (_error != null) {
      final isAuth = _error!.contains('Сессия истекла') || _error!.contains('authenticated');
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(PhosphorIconsRegular.warningCircle, size: 28, color: AppColors.danger),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
              ),
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
                AppSecondaryButton(
                  label: 'Повторить попытку',
                  icon: PhosphorIconsRegular.arrowClockwise,
                  onPressed: _loadHistory,
                ),
            ],
          ),
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.archive, size: 36, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            const SizedBox(height: 8),
            Text('История смен пуста', style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _history[index];
        final shiftId = item['id'];
        final isOpen = item['is_open'] == true;
        final totalRev = (item['total_revenue'] as num?)?.toDouble() ?? 0.0;
        final diff = (item['discrepancy'] as num?)?.toDouble();

        String dateStr = '-';
        if (item['opened_at'] != null) {
          final parsed = DateTime.tryParse(item['opened_at'].toString());
          if (parsed != null) {
            dateStr = DateFormat('dd.MM, HH:mm').format(parsed.toLocal());
          }
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isOpen
                  ? AppColors.brandTertiary.withValues(alpha: 0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isOpen
                      ? AppColors.success.withValues(alpha: 0.15)
                      : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '#$shiftId',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isOpen ? AppColors.success : (isDark ? AppColors.darkText : AppColors.lightText),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isOpen ? 'Смена активна' : 'Смена закрыта',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isOpen ? AppColors.success : (isDark ? AppColors.darkText : AppColors.lightText),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '($dateStr)',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Выручка: ${totalRev.toCurrency(context)} • ${item['orders_count'] ?? 0} чеков',
                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                    ),
                  ],
                ),
              ),
              if (!isOpen && diff != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: diff == 0
                        ? AppColors.success.withValues(alpha: 0.1)
                        : (diff < 0
                            ? AppColors.danger.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    diff == 0 ? 'Точно' : (diff < 0 ? diff.toCurrency(context) : '+${diff.toCurrency(context)}'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
