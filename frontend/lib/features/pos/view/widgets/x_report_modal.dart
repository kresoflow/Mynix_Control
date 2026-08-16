import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/pos/repository/shift_repository.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class XReportModal extends StatefulWidget {
  const XReportModal({super.key});

  @override
  State<XReportModal> createState() => _XReportModalState();
}

class _XReportModalState extends State<XReportModal> {
  late final ShiftRepository _shiftRepository;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _shiftRepository = ShiftRepository(apiClient.dio);
    _loadXReport();
  }

  Future<void> _loadXReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final report = await _shiftRepository.getXReport();
      if (mounted) {
        setState(() {
          _report = report;
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

    return MynixDialog(
      title: 'X-ОТЧЕТ (Текущий)',
      icon: PhosphorIconsRegular.receipt,
      width: 440,
      content: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('Ошибка: $_error', style: const TextStyle(color: AppColors.danger)),
                )
              : _report != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRow('Статус смены', _report!['is_open'] == true ? 'ОТКРЫТА' : 'ЗАКРЫТА', isDark, isHighlight: true),
                        const SizedBox(height: 8),
                        _buildRow('Кассовый остаток на начало', (num.tryParse(_report!['opening_cash'].toString()) ?? 0).toCurrency(context), isDark),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              _buildIconRow(PhosphorIconsRegular.money, 'Выручка (Наличные)', (num.tryParse(_report!['cash_sales'].toString()) ?? 0).toCurrency(context), isDark),
                              const SizedBox(height: 8),
                              _buildIconRow(PhosphorIconsRegular.deviceMobile, 'Выручка (Перевод)', (num.tryParse(_report!['transfer_sales'].toString()) ?? 0).toCurrency(context), isDark),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(height: 1),
                              ),
                              _buildRow('ИТОГО ВЫРУЧКА', (num.tryParse(_report!['total_revenue'].toString()) ?? 0).toCurrency(context), isDark, isBold: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRow('Всего заказов', '${_report!['orders_count'] ?? 0} шт.', isDark),
                        const SizedBox(height: 8),
                        _buildRow('Средний чек', (num.tryParse(_report!['average_check'].toString()) ?? 0).toCurrency(context), isDark),
                        const SizedBox(height: 8),
                        _buildRow('Изъятие / Расходы', (num.tryParse(_report!['cash_expenses'].toString()) ?? 0).toCurrency(context), isDark),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        _buildIconRow(
                          PhosphorIconsRegular.coins,
                          'Ожидается в кассе',
                          (num.tryParse(_report!['expected_cash'].toString()) ?? 0).toCurrency(context),
                          isDark,
                          isBold: true,
                          valueColor: AppColors.success,
                          iconColor: AppColors.success,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
      actions: [
        AppPrimaryButton(
          label: 'Закрыть',
          height: 42,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, bool isDark, {bool isBold = false, bool isHighlight = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor ?? (isHighlight ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText)),
            fontWeight: isBold || isHighlight ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildIconRow(IconData icon, String label, String value, bool isDark, {bool isBold = false, Color? valueColor, Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor ?? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor ?? (isDark ? AppColors.darkText : AppColors.lightText),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
