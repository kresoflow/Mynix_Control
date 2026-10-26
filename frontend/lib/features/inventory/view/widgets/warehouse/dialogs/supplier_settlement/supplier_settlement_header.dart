// ==============================================================================
// Title: Supplier Settlement Header
// Path: frontend/lib/features/inventory/view/widgets/warehouse/dialogs/supplier_settlement/supplier_settlement_header.dart
// Description: Шапка и панель фильтрации окна взаиморасчетов поставщика.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/models/supplier.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ─── 1. Шапка и тулбар взаиморасчетов ─────────────────────────────────────────

/// [UI-KIT] Верхняя часть модального окна взаиморасчетов:
/// - Баланс поставщика (долг / аванс).
/// - Экспорт акта сверки в PDF и кнопка закрытия.
/// - Сегментированный фильтр и кнопки быстрых действий.
class SupplierSettlementHeader extends StatelessWidget {
  final Supplier supplier;
  final String currency;
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onDownloadPdf;
  final VoidCallback onClose;
  final VoidCallback onAddManualDebt;
  final VoidCallback onAddPayment;

  const SupplierSettlementHeader({
    super.key,
    required this.supplier,
    required this.currency,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.onDownloadPdf,
    required this.onClose,
    required this.onAddManualDebt,
    required this.onAddPayment,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDebt = supplier.balance < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Верхний ряд: Название, баланс, PDF и закрытие ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.15),
                    borderRadius: AppRadii.inputRadius,
                  ),
                  child: Icon(
                    PhosphorIconsRegular.wallet,
                    color: AppColors.brandPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      style: AppTextStyles.h2.copyWith(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasDebt
                          ? 'Текущий долг: ${supplier.balance.abs().toStringAsFixed(2)} $currency'
                          : 'Баланс: +${supplier.balance.toStringAsFixed(2)} $currency (Аванс)',
                      style: AppTextStyles.caption.copyWith(
                        color: hasDebt ? AppColors.danger : AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                AppButton(
                  label: 'Акт сверки (PDF)',
                  icon: PhosphorIconsRegular.filePdf,
                  variant: AppButtonVariant.secondary,
                  onPressed: onDownloadPdf,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    PhosphorIconsRegular.x,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    size: 22,
                  ),
                  onPressed: onClose,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // ── Нижний ряд: Фильтр и кнопки добавления ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppSegmentedControl<String>(
              selectedValue: activeFilter,
              size: AppSegmentedSize.sm,
              onValueChanged: onFilterChanged,
              items: const [
                AppSegmentedItem(value: 'all', label: 'Все'),
                AppSegmentedItem(value: 'invoices', label: 'Накладные'),
                AppSegmentedItem(value: 'payments', label: 'Выплаты'),
                AppSegmentedItem(value: 'manual', label: 'Ручные'),
              ],
            ),
            Row(
              children: [
                AppSecondaryButton(
                  label: 'Начислить долг',
                  icon: PhosphorIconsRegular.plus,
                  size: AppButtonSize.sm,
                  onPressed: onAddManualDebt,
                ),
                const SizedBox(width: 8),
                AppPrimaryButton(
                  label: 'Внести оплату',
                  icon: PhosphorIconsRegular.money,
                  size: AppButtonSize.sm,
                  onPressed: onAddPayment,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
