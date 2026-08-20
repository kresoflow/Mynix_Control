import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/features/pos/repository/shift_repository.dart';

class ShiftHistoryTab extends StatefulWidget {
  const ShiftHistoryTab({super.key});

  @override
  State<ShiftHistoryTab> createState() => _ShiftHistoryTabState();
}

class _ShiftHistoryTabState extends State<ShiftHistoryTab> {
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text('Ошибка: $_error', style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(PhosphorIconsRegular.arrowClockwise, size: 14),
              label: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Column(
            children: [
              Icon(PhosphorIconsRegular.archive, size: 36, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              const SizedBox(height: 8),
              Text(
                'История смен пуста',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 320,
      child: ListView.separated(
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
                    color: isOpen ? AppColors.success.withValues(alpha: 0.15) : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
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
                          Text('($dateStr)', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
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
                          : (diff < 0 ? AppColors.danger.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      diff == 0 ? '✓ Точно' : (diff < 0 ? '${diff.toCurrency(context)}' : '+${diff.toCurrency(context)}'),
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
      ),
    );
  }
}
