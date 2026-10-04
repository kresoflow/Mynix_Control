// ==============================================================================
// ВИДЖЕТ: Шапка модального окна оприходования товара (Receive Document Header)
// ДОМЕН: features/inventory/view/widgets/warehouse/dialogs/receive_document/
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';

class ReceiveDocumentHeader extends StatelessWidget {
  final VoidCallback onClose;

  const ReceiveDocumentHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 20, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              PhosphorIconsRegular.truck,
              color: AppColors.lightSurface,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Новая Приходная Накладная',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              PhosphorIconsRegular.x,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
            onPressed: onClose,
            tooltip: 'Закрыть',
          ),
        ],
      ),
    );
  }
}
