import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';


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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Итого к оплате:', style: TextStyle(color: Colors.grey, fontSize: 14)),
              Text('${totalSum.toStringAsFixed(2)} $currency', style: AppTextStyles.h1),
            ],
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: onCancel,
            child: const Text('Отмена'),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: isSaving ? null : onSaveDraft,
            icon: const Icon(PhosphorIconsRegular.floppyDisk),
            label: const Text('Сохранить черновик'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: isSaving ? null : onSaveComplete,
            icon: const Icon(PhosphorIconsRegular.checkCircle),
            label: const Text('Провести документ (Ctrl+S)'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
