import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';

class ReceiveDocumentFooter extends StatelessWidget {
  final double totalSum;
  final String currency;
  final bool isSaving;
  final String paymentStatus; // "unpaid", "paid", "partial"
  final String paymentMethod; // "cash", "card", "bank_transfer"
  final TextEditingController paidAmountController;
  final ValueChanged<String> onPaymentStatusChanged;
  final ValueChanged<String> onPaymentMethodChanged;
  final VoidCallback onCancel;
  final VoidCallback onSaveDraft;
  final VoidCallback onSaveComplete;

  const ReceiveDocumentFooter({
    super.key,
    required this.totalSum,
    required this.currency,
    required this.isSaving,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.paidAmountController,
    required this.onPaymentStatusChanged,
    required this.onPaymentMethodChanged,
    required this.onCancel,
    required this.onSaveDraft,
    required this.onSaveComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10141D) : AppColors.lightBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF242C3D) : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Итого к оплате
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ИТОГО:',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
              Text(
                '${totalSum.toStringAsFixed(2)} $currency',
                style: AppTextStyles.h1.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // 2. Блок условий оплаты
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
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
                      context,
                      label: 'Постоплата',
                      icon: PhosphorIconsRegular.clockCounterClockwise,
                      isSelected: paymentStatus == 'unpaid',
                      selectedColor: AppColors.warning,
                      onTap: () => onPaymentStatusChanged('unpaid'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 4),
                    _buildOptionChip(
                      context,
                      label: 'Оплачено',
                      icon: PhosphorIconsRegular.checkCircle,
                      isSelected: paymentStatus == 'paid',
                      selectedColor: AppColors.success,
                      onTap: () => onPaymentStatusChanged('paid'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 4),
                    _buildOptionChip(
                      context,
                      label: 'Частично',
                      icon: PhosphorIconsRegular.percent,
                      isSelected: paymentStatus == 'partial',
                      selectedColor: AppColors.info,
                      onTap: () => onPaymentStatusChanged('partial'),
                      isDark: isDark,
                    ),

                    // Способ оплаты (если не в долг)
                    if (paymentStatus != 'unpaid') ...[
                      const SizedBox(width: 8),
                      Container(
                        height: 20,
                        width: 1,
                        color: isDark ? Colors.white24 : Colors.black26,
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

                    // Поле частичной суммы
                    if (paymentStatus == 'partial') ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 75,
                        height: 28,
                        child: TextField(
                          controller: paidAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'Сумма',
                            filled: true,
                            fillColor: isDark ? Colors.white10 : Colors.black12,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 3. Кнопки действий
          AppButton.ghost(
            label: 'Отмена',
            height: 38,
            onPressed: onCancel,
          ),
          const SizedBox(width: 8),
          AppButton.secondary(
            label: 'Черновик',
            icon: PhosphorIconsRegular.floppyDisk,
            height: 38,
            isLoading: isSaving,
            onPressed: isSaving ? null : onSaveDraft,
          ),
          const SizedBox(width: 8),
          AppButton.primary(
            label: 'Провести (Ctrl+S)',
            icon: PhosphorIconsRegular.checkCircle,
            customColor: AppColors.success,
            height: 38,
            isLoading: isSaving,
            onPressed: isSaving ? null : onSaveComplete,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
    required bool isDark,
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
              : (isDark ? Colors.transparent : Colors.transparent),
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
              style: TextStyle(
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

