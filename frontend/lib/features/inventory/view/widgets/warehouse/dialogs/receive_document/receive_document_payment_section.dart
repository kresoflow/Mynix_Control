import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOptionChip(
            label: 'Постоплата',
            icon: PhosphorIconsRegular.clockCounterClockwise,
            isSelected: paymentStatus == 'unpaid',
            selectedColor: AppColors.warning,
            onTap: () => onPaymentStatusChanged('unpaid'),
          ),
          const SizedBox(width: 4),
          _buildOptionChip(
            label: 'Оплачено',
            icon: PhosphorIconsRegular.checkCircle,
            isSelected: paymentStatus == 'paid',
            selectedColor: AppColors.success,
            onTap: () => onPaymentStatusChanged('paid'),
          ),
          const SizedBox(width: 4),
          _buildOptionChip(
            label: 'Частично',
            icon: PhosphorIconsRegular.percent,
            isSelected: paymentStatus == 'partial',
            selectedColor: AppColors.info,
            onTap: () => onPaymentStatusChanged('partial'),
          ),
          if (paymentStatus != 'unpaid') ...[
            const SizedBox(width: 8),
            Container(
              height: 20,
              width: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            const SizedBox(width: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: paymentMethod,
                isDense: true,
                dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'cash',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsRegular.money, size: 14, color: AppColors.brandPrimary),
                        const SizedBox(width: 6),
                        const Text('Наличные'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'card',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsRegular.creditCard, size: 14, color: AppColors.brandPrimary),
                        const SizedBox(width: 6),
                        const Text('Карта'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'bank_transfer',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsRegular.bank, size: 14, color: AppColors.brandPrimary),
                        const SizedBox(width: 6),
                        const Text('Расчетный счет'),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) onPaymentMethodChanged(val);
                },
              ),
            ),
          ],
          if (paymentStatus == 'partial') ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 75,
              height: 28,
              child: TextField(
                controller: paidAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Сумма',
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? selectedColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? selectedColor : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? selectedColor : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
