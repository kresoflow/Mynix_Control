// ==============================================================================
// МОДУЛЬ: Склад / Секция оплаты приходной накладной
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'receive_document_amount_field.dart';

/// Секция выбора статуса оплаты (Постоплата / Оплачено / Частично)
/// и способа оплаты (Наличные, Перевод, Расчетный счет).
class ReceiveDocumentPaymentSection extends StatelessWidget {
  final bool isDark;
  final String paymentStatus;
  final String paymentMethod;
  final TextEditingController paidAmountController;
  final ValueChanged<String> onPaymentStatusChanged;
  final ValueChanged<String> onPaymentMethodChanged;

  const ReceiveDocumentPaymentSection({
    super.key,
    required this.isDark,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.paidAmountController,
    required this.onPaymentStatusChanged,
    required this.onPaymentMethodChanged,
  });

  // Допустимые способы оплаты для поставщиков: Наличные, Перевод, Расчетный счет
  static const List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'cash',
      'label': 'Наличные',
      'icon': PhosphorIconsRegular.money,
    },
    {
      'id': 'transfer',
      'label': 'Перевод',
      'icon': PhosphorIconsRegular.arrowsLeftRight,
    },
    {
      'id': 'bank_transfer',
      'label': 'Расчетный счет',
      'icon': PhosphorIconsRegular.bank,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final validMethod = _paymentMethods.any((m) => m['id'] == paymentMethod)
        ? paymentMethod
        : 'cash';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          // ── 1. Статус: Постоплата ──────────────────────────────────
          _buildStatusChip(
            label: 'Постоплата',
            icon: PhosphorIconsRegular.clockCounterClockwise,
            isSelected: paymentStatus == 'unpaid',
            onTap: () => onPaymentStatusChanged('unpaid'),
          ),
          const SizedBox(width: 4),

          // ── 2. Статус: Оплачено ────────────────────────────────────
          _buildStatusChip(
            label: 'Оплачено',
            icon: PhosphorIconsRegular.checkCircle,
            isSelected: paymentStatus == 'paid',
            onTap: () => onPaymentStatusChanged('paid'),
          ),
          const SizedBox(width: 4),

          // ── 3. Статус: Частично ────────────────────────────────────
          _buildStatusChip(
            label: 'Частично',
            icon: PhosphorIconsRegular.percent,
            isSelected: paymentStatus == 'partial',
            onTap: () => onPaymentStatusChanged('partial'),
          ),

          // ── 4. Способ оплаты и сумма (если не постоплата) ───────────
          if (paymentStatus != 'unpaid') ...[
            const SizedBox(width: 8),
            Container(
              height: 24,
              width: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            const SizedBox(width: 8),
            _buildMethodDropdown(validMethod),
            const SizedBox(width: 8),
            ReceiveDocumentAmountField(
              controller: paidAmountController,
              isDark: isDark,
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeBg = AppColors.brandPrimary.withValues(alpha: isDark ? 0.16 : 0.10);
    final activeBorder = AppColors.brandPrimary.withValues(alpha: 0.8);
    final activeColor = AppColors.brandPrimary;

    final inactiveBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final inactiveBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inactiveColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeBorder : inactiveBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodDropdown(String currentMethod) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentMethod,
          isDense: true,
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
          items: _paymentMethods.map((m) {
            return DropdownMenuItem<String>(
              value: m['id'] as String,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    m['icon'] as IconData,
                    size: 14,
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(m['label'] as String),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onPaymentMethodChanged(val);
          },
        ),
      ),
    );
  }
}
