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
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ИТОГО К ОПЛАТЕ:',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
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
          AppButton.ghost(
            label: 'Отмена',
            height: 46,
            onPressed: onCancel,
          ),
          const SizedBox(width: 12),
          AppButton.secondary(
            label: 'Сохранить черновик',
            icon: PhosphorIconsRegular.floppyDisk,
            height: 46,
            isLoading: isSaving,
            onPressed: isSaving ? null : onSaveDraft,
          ),
          const SizedBox(width: 12),
          AppButton.primary(
            label: 'Провести документ (Ctrl+S)',
            icon: PhosphorIconsRegular.checkCircle,
            customColor: AppColors.success,
            height: 46,
            isLoading: isSaving,
            onPressed: isSaving ? null : onSaveComplete,
          ),
        ],
      ),
    );
  }
}
