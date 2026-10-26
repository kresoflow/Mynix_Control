// ==============================================================================
// Title: StockErrorView (stock_error_view.dart)
// Path: frontend/lib/features/inventory/view/widgets/warehouse/stock/stock_error_view.dart
// Description: Экран ошибки загрузки номенклатуры склада с кнопкой повтора.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';

// ─── 1. Виджет ошибки загрузки остатков ───────────────────────────────────────

/// [UI-KIT] Состояние ошибки при сетевом сбое получения остатков
class StockErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const StockErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            PhosphorIconsRegular.warningCircle,
            size: 48,
            color: AppColors.danger,
          ),
          const SizedBox(height: 12),
          Text(
            'Не удалось загрузить остатки склада',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 6),
          Text(
            errorMessage.replaceAll('Exception: ', ''),
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          AppSecondaryButton(
            onPressed: onRetry,
            icon: PhosphorIconsRegular.arrowsClockwise,
            label: 'Повторить попытку',
          ),
        ],
      ),
    );
  }
}
