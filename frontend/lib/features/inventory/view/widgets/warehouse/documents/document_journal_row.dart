import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/features/inventory/models/document.dart';

class DocumentJournalRow extends StatelessWidget {
  final InventoryDocument doc;
  final VoidCallback? onTap;

  const DocumentJournalRow({
    super.key,
    required this.doc,
    this.onTap,
  });

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

  String _getTypeLabel(String type) {
    if (type == 'receipt') return 'Приход';
    if (type == 'write_off') return 'Списание';
    if (type == 'inventory') return 'Инвентаризация';
    return type;
  }

  Color _getTypeColor(String type) {
    if (type == 'receipt') return AppColors.info;
    if (type == 'write_off') return Colors.deepOrange;
    if (type == 'inventory') return Colors.purple;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 50, child: Text('#${doc.id}')),
            Expanded(
              flex: 2,
              child: Text(DateFormat('dd.MM.yyyy HH:mm').format(doc.date.toLocal())),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(doc.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getTypeLabel(doc.type),
                    style: TextStyle(
                      color: _getTypeColor(doc.type),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                doc.type == 'receipt'
                    ? (doc.supplierName ?? 'Неизвестный поставщик')
                    : (doc.reason ?? '-'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                doc.totalAmount.toCurrency(context),
                style: AppTextStyles.h3,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(doc.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getStatusLabel(doc.status),
                    style: TextStyle(
                      color: _getStatusColor(doc.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 50,
              child: Icon(PhosphorIconsRegular.caretRight, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
