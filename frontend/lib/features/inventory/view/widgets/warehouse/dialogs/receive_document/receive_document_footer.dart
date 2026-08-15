import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';

class ReceiveDocumentFooter extends StatelessWidget {
  final double totalSum;
  final String currency;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSaveDraft;
  final VoidCallback onSaveComplete;

  const ReceiveDocumentFooter({
    super.key,
    required this.totalSum,
    required this.currency,
    required this.isSaving,
    required this.onCancel,
    required this.onSaveDraft,
    required this.onSaveComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Итого к оплате:',
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${totalSum.toStringAsFixed(2)} $currency',
                style: AppTextStyles.h1.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          AppButton.outline(
            label: 'Отмена',
            height: 44,
            onPressed: onCancel,
          ),
          const SizedBox(width: 12),
          AppButton.secondary(
            label: 'Сохранить черновик',
            icon: PhosphorIconsRegular.floppyDisk,
            height: 44,
            isLoading: isSaving,
            onPressed: isSaving ? null : onSaveDraft,
          ),
          const SizedBox(width: 12),
          AppButton.primary(
            label: 'Провести документ (Ctrl+S)',
            icon: PhosphorIconsRegular.checkCircle,
            customColor: AppColors.success,
            height: 44,
            isLoading: isSaving,
            onPressed: isSaving ? null : onSaveComplete,
          ),
        ],
      ),
    );
  }
}
