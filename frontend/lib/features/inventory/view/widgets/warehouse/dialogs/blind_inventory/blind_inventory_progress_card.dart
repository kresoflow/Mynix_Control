// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

// ==============================================================================
// 2. КОМПОНЕНТ СВОДКИ ИНВЕНТАРИЗАЦИИ
// ==============================================================================
/// [ИНВАРИАНТ] Информационная плашка прогресса заполнения ревизии склада.
class BlindInventoryProgressCard extends StatelessWidget {
  final int filledCount;
  final int totalCount;
  final VoidCallback? onToggleCart;
  final bool isCartOpen;

  const BlindInventoryProgressCard({
    super.key,
    required this.filledCount,
    required this.totalCount,
    this.onToggleCart,
    this.isCartOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cartButton() {
      final color = isCartOpen
          ? AppColors.pureWhite
          : (filledCount > 0 ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext));
      final bg = isCartOpen
          ? AppColors.brandPrimary
          : (filledCount > 0
              ? AppColors.brandPrimary.withValues(alpha: isDark ? 0.16 : 0.10)
              : (isDark ? AppColors.darkCard : AppColors.lightBg));
      final border = isCartOpen || filledCount > 0
          ? AppColors.brandPrimary.withValues(alpha: 0.4)
          : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

      return InkWell(
        onTap: onToggleCart,
        borderRadius: AppRadii.badgeRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadii.badgeRadius, border: Border.all(color: border)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsRegular.clipboardText, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                'Посчитано: $filledCount из $totalCount',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
              if (onToggleCart != null) ...[
                const SizedBox(width: 4),
                Icon(isCartOpen ? PhosphorIconsRegular.caretDown : PhosphorIconsRegular.caretUp, size: 12, color: color),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.inputRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          cartButton(),
          Text(
            'Все не введенные остатки не изменятся',
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
