import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/inventory/models/document.dart';

class DocumentDetailHeader extends StatelessWidget {
  final InventoryDocument doc;

  const DocumentDetailHeader({super.key, required this.doc});

  Color _getStatusColor(String status) {
    if (status == 'completed') return AppColors.success;
    if (status == 'draft') return AppColors.warning;
    if (status == 'cancelled') return AppColors.danger;
    return Colors.grey;
  }

  String _getStatusLabel(String status) {
    if (status == 'completed') return 'Проведен';
    if (status == 'draft') return 'Черновик';
    if (status == 'cancelled') return 'Отменен';
    return status;
  }

  String _getTypeTitle(String type) {
    if (type == 'receipt') return 'Приходная накладная';
    if (type == 'write_off') return 'Акт списания';
    if (type == 'inventory') return 'Акт инвентаризации';
    return 'Документ склада';
  }

  IconData _getTypeIcon(String type) {
    if (type == 'receipt') return PhosphorIconsFill.truck;
    if (type == 'write_off') return PhosphorIconsFill.trash;
    if (type == 'inventory') return PhosphorIconsFill.clipboardText;
    return PhosphorIconsFill.fileText;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(doc.status);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTypeIcon(doc.type),
              color: AppColors.brandPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '${_getTypeTitle(doc.type)} #${doc.id}',
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getStatusLabel(doc.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd.MM.yyyy • HH:mm').format(doc.date.toLocal()),
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.x, size: 18),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Закрыть',
          ),
        ],
      ),
    );
  }
}
