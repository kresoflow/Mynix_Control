import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/models/supplier.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/mynix_date_time_picker.dart';
import 'receive_document_smart_header.dart';
import 'receive_document_supplier_select.dart';

class ReceiveDocumentMetaRow extends StatelessWidget {
  final List<Supplier> suppliers;
  final int? selectedSupplierId;
  final ValueChanged<int?> onSupplierChanged;
  final VoidCallback onAddSupplier;
  final TextEditingController invoiceController;
  final TextEditingController reasonController;
  final DateTime documentDate;
  final ValueChanged<DateTime> onDateChanged;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final int? selectedParentId;
  final int? selectedChildId;
  final ValueChanged<int?> onParentChanged;
  final ValueChanged<int?> onChildChanged;
  final bool isAdHocPurchase;
  final ValueChanged<bool>? onAdHocChanged;

  const ReceiveDocumentMetaRow({
    super.key,
    required this.suppliers,
    required this.selectedSupplierId,
    required this.onSupplierChanged,
    required this.onAddSupplier,
    required this.invoiceController,
    required this.reasonController,
    required this.documentDate,
    required this.onDateChanged,
    required this.tabIndex,
    required this.onTabChanged,
    required this.selectedParentId,
    required this.selectedChildId,
    required this.onParentChanged,
    required this.onChildChanged,
    this.isAdHocPurchase = false,
    this.onAdHocChanged,
  });

  InputDecoration _buildInputDecoration(BuildContext context, String label, IconData icon, bool isDark) {
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.caption.copyWith(
        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
      ),
      filled: true,
      fillColor: bg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      prefixIcon: Icon(icon, size: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = '${documentDate.hour.toString().padLeft(2, '0')}:${documentDate.minute.toString().padLeft(2, '0')}';
    final dateStr = '${documentDate.day.toString().padLeft(2, '0')}.${documentDate.month.toString().padLeft(2, '0')}.${documentDate.year}, $timeStr';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              // 1. Поставщик
              Expanded(
                flex: 3,
                child: ReceiveDocumentSupplierSelect(
                  suppliers: suppliers,
                  selectedSupplierId: selectedSupplierId,
                  onSupplierChanged: onSupplierChanged,
                  onAdHocChanged: onAdHocChanged,
                  onAddSupplier: onAddSupplier,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),

              // 2. Номер накладной
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 46,
                  child: TextField(
                    controller: invoiceController,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                    decoration: _buildInputDecoration(context, 'Номер накладной', PhosphorIconsRegular.hash, isDark),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 3. Дата и время документа (Mynix Smart DateTime Picker)
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 46,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final picked = await showMynixDateTimePicker(
                        context,
                        initialDateTime: documentDate,
                      );
                      if (picked != null) {
                        onDateChanged(picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: _buildInputDecoration(context, 'Дата и время', PhosphorIconsRegular.calendarBlank, isDark),
                      child: Text(
                        dateStr,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 4. Комментарий
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 46,
                  child: TextField(
                    controller: reasonController,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                    decoration: _buildInputDecoration(context, 'Комментарий', PhosphorIconsRegular.textAa, isDark),
                  ),
                ),
              ),
            ],
          ),
          if (isAdHocPurchase) ...[
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: _buildInputDecoration(context, 'Откуда закупка? (базар, продавец, место)', PhosphorIconsRegular.mapPin, isDark),
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ReceiveDocumentSmartHeader(
            tabIndex: tabIndex,
            onTabChanged: onTabChanged,
            selectedParentId: selectedParentId,
            selectedChildId: selectedChildId,
            onParentChanged: onParentChanged,
            onChildChanged: onChildChanged,
          ),
        ],
      ),
    );
  }
}
