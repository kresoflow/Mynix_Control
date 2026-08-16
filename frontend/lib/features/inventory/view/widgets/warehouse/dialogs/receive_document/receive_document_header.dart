import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';


class ReceiveDocumentHeader extends StatelessWidget {
  final VoidCallback onClose;
  
  const ReceiveDocumentHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(PhosphorIconsRegular.truck, color: AppColors.info, size: 28),
          ),
          const SizedBox(width: 16),
          Text('Новая Приходная Накладная', style: AppTextStyles.h2),
          const Spacer(),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.x),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
