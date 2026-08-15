import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/models/supplier.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add/bulk_add_category_selector.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_segmented_tab.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: DropdownButtonFormField<int?>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Поставщик (необязательно)',
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
                            prefixIcon: const Icon(PhosphorIconsRegular.buildings, size: 18),
                          ),
                          initialValue: selectedSupplierId,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Без поставщика'),
                            ),
                            ...suppliers.map((s) {
                              return DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              );
                            }),
                          ],
                          onChanged: onSupplierChanged,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Добавить поставщика',
                      child: Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: bg,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                          color: AppColors.brandPrimary,
                          onPressed: onAddSupplier,
                        ),
                      ),
                    ),
                  ],
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
                    decoration: InputDecoration(
                      labelText: 'Номер накладной',
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
                      prefixIcon: const Icon(PhosphorIconsRegular.hash, size: 18),
                    ),
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
                    decoration: InputDecoration(
                      labelText: 'Комментарий',
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
                      prefixIcon: const Icon(PhosphorIconsRegular.textAa, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // SMART CREATION TABS & CATEGORIES
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.magicWand, color: AppColors.info, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Умное создание',
                      style: AppTextStyles.h3.copyWith(color: AppColors.info, fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Новые названия будут автоматически созданы в указанной категории.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.info),
                      ),
                    ),
                    AppSegmentedTab<int>(
                      items: const [
                        AppSegmentedTabItem(value: 1, label: 'Витрина'),
                        AppSegmentedTabItem(value: 2, label: 'Сырье'),
                      ],
                      selectedValue: tabIndex,
                      onValueChanged: onTabChanged,
                      height: 36,
                      isCompact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BulkAddCategorySelector(
                  tabIndex: tabIndex,
                  selectedParentId: selectedParentId,
                  selectedChildId: selectedChildId,
                  onParentChanged: onParentChanged,
                  onChildChanged: onChildChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
