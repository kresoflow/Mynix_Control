import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
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

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.receipt, color: AppColors.brandPrimary, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'X-ОТЧЕТ (Текущий)',
                      style: AppTextStyles.h2.copyWith(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('Ошибка: $_error', style: const TextStyle(color: Colors.red)),
              )
            else if (_report != null) ...[
              _buildRow('Статус смены', _report!['is_open'] == true ? 'ОТКРЫТА' : 'ЗАКРЫТА', isDark, isHighlight: true),
              _buildRow('Кассовый остаток на начало', (num.tryParse(_report!['opening_cash'].toString()) ?? 0).toCurrency(context), isDark),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildRow('💵 Выручка (Наличные)', (num.tryParse(_report!['cash_sales'].toString()) ?? 0).toCurrency(context), isDark),
                    const SizedBox(height: 6),
                    _buildRow('📱 Выручка (Перевод)', (num.tryParse(_report!['transfer_sales'].toString()) ?? 0).toCurrency(context), isDark),
                    const Divider(height: 16),
                    _buildRow('ИТОГО ВЫРУЧКА', (num.tryParse(_report!['total_revenue'].toString()) ?? 0).toCurrency(context), isDark, isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildRow('Всего заказов', '${_report!['orders_count'] ?? 0} шт.', isDark),
              _buildRow('Средний чек', (num.tryParse(_report!['average_check'].toString()) ?? 0).toCurrency(context), isDark),
              _buildRow('Изъятие / Расходы', (num.tryParse(_report!['cash_expenses'].toString()) ?? 0).toCurrency(context), isDark),
              const Divider(height: 24),
              _buildRow(
                '💰 Ожидается в кассе', 
                (num.tryParse(_report!['expected_cash'].toString()) ?? 0).toCurrency(context), 
                isDark, 
                isBold: true,
                valueColor: AppColors.success,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ЗАКРЫТЬ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, bool isDark, {bool isBold = false, bool isHighlight = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
      ),
    );
  }
}
