// ==============================================================================
// Title: SupplierBalanceBadge (supplier_balance_badge.dart)
// Path: frontend/lib/features/inventory/view/widgets/warehouse/supplier_balance_badge.dart
// Description: Бейдж отображения долга или аванса взаиморасчетов с поставщиком.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

// ─── 1. Бейдж финансового сальдо контрагента ──────────────────────────────────

/// [UI-KIT] Компонент индикации текущего сальдо (долг / аванс / 0.00)
class SupplierBalanceBadge extends StatelessWidget {
  final double balance;
  final String currency;
  final bool isDark;

  const SupplierBalanceBadge({
    super.key,
    required this.balance,
    required this.currency,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (balance < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: AppRadii.inputRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              PhosphorIconsRegular.warningCircle,
              size: 13,
              color: AppColors.danger,
            ),
            const SizedBox(width: 4),
            Text(
              'Долг: ${balance.abs().toStringAsFixed(2)} $currency',
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      );
    } else if (balance > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: AppRadii.inputRadius,
        ),
        child: Text(
          '+${balance.toStringAsFixed(2)} $currency (Аванс)',
          style: AppTextStyles.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
      );
    }

    return Text(
      '0.00 $currency',
      style: AppTextStyles.caption.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
      ),
    );
  }
}
