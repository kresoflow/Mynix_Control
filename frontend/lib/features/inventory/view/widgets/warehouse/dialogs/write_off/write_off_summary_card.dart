import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

class WriteOffSummaryCard extends StatelessWidget {
  final int itemsCount;
  final double totalUnits;
  final double totalAmount;
  final String currency;
  final VoidCallback? onToggleCart;
  final bool isCartOpen;

  const WriteOffSummaryCard({
    super.key,
    required this.itemsCount,
    required this.totalUnits,
    required this.totalAmount,
    required this.currency,
    this.onToggleCart,
    this.isCartOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cartBadge() {
      final color = isCartOpen
          ? AppColors.pureWhite
          : (itemsCount > 0 ? AppColors.danger : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext));
      final bg = isCartOpen
          ? AppColors.danger
          : (itemsCount > 0
              ? AppColors.danger.withValues(alpha: isDark ? 0.16 : 0.10)
              : (isDark ? AppColors.darkCard : AppColors.lightBg));
      final border = isCartOpen || itemsCount > 0
          ? AppColors.danger.withValues(alpha: 0.4)
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
              Icon(PhosphorIconsRegular.shoppingCart, size: 14, color: color),
              const SizedBox(width: 6),
              Text('$itemsCount поз.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.radiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              cartBadge(),
              const SizedBox(width: 10),
              Text(
                'Всего: ${totalUnits.toStringAsFixed(0)} ед.',
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'ИТОГО СПИСАНИЕ: ',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
              Text(
                '${totalAmount.toStringAsFixed(2)} $currency',
                style: AppTextStyles.h2.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
