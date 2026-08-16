import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/models/supplier.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'receive_document_smart_header.dart';
import 'receive_document_supplier_select.dart';

class ReceiveDocumentMetaRow extends StatelessWidget {
  final List<Supplier> suppliers;
  final int? selectedSupplierId;
  final ValueChanged<int?> onSupplierChanged;
  final VoidCallback onAddSupplier;
  final TextEditingController invoiceController;
  final TextEditingController reasonController;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final int? selectedParentId;
  final int? selectedChildId;
  final ValueChanged<int?> onParentChanged;
  final ValueChanged<int?> onChildChanged;

  const ReceiveDocumentMetaRow({
    super.key,
    required this.suppliers,
    required this.selectedSupplierId,
    required this.onSupplierChanged,
    required this.onAddSupplier,
    required this.invoiceController,
    required this.reasonController,
    required this.tabIndex,
    required this.onTabChanged,
    required this.selectedParentId,
    required this.selectedChildId,
    required this.onParentChanged,
    required this.onChildChanged,
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

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ReceiveDocumentSupplierSelect(
                  suppliers: suppliers,
                  selectedSupplierId: selectedSupplierId,
                  onSupplierChanged: onSupplierChanged,
                  onAddSupplier: onAddSupplier,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
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
              const SizedBox(width: 16),
              Expanded(
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
