import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'receive_document_payment_section.dart';

class ReceiveDocumentFooter extends StatelessWidget {
  final double totalSum;
  final ValueListenable<double>? totalSumListenable;
  final String currency;
  final bool isSaving;
  final String paymentStatus;
  final String paymentMethod;
  final TextEditingController paidAmountController;
  final ValueChanged<String> onPaymentStatusChanged;
  final ValueChanged<String> onPaymentMethodChanged;
  final VoidCallback onCancel;
  final VoidCallback onSaveDraft;
  final VoidCallback onSaveComplete;

  const ReceiveDocumentFooter({
    super.key,
    required this.totalSum,
    this.totalSumListenable,
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

    Widget totalTextWidget(double sum) {
      return Text(
        '${sum.toStringAsFixed(2)} $currency',
        style: AppTextStyles.h1.copyWith(
          color: isDark ? AppColors.darkText : AppColors.lightText,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
              if (totalSumListenable != null)
                ValueListenableBuilder<double>(
                  valueListenable: totalSumListenable!,
                  builder: (_, sum, __) => totalTextWidget(sum),
                )
              else
                totalTextWidget(totalSum),
            ],
          ),
          const SizedBox(width: 14),

          // 2. Блок условий оплаты
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ReceiveDocumentPaymentSection(
                isDark: isDark,
                paymentStatus: paymentStatus,
                paymentMethod: paymentMethod,
                paidAmountController: paidAmountController,
                onPaymentStatusChanged: onPaymentStatusChanged,
                onPaymentMethodChanged: onPaymentMethodChanged,
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
            customColor: AppColors.success,
            height: 38,
            isLoading: isSaving,
            onPressed: isSaving ? null : onSaveComplete,
          ),
        ],
      ),
    );
  }
}
