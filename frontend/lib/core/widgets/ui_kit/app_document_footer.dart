// ==============================================================================
// УНИФИЦИРОВАННАЯ ПАНЕЛЬ ИТОГОВ И ДЕЙСТВИЙ (APP DOCUMENT FOOTER - ДВУХЪЯРУСНЫЙ)
// ==============================================================================
//
// [ИНВАРИАНТ] Золотой стандарт Приходки: двухъярусный подвал.
// Сумма и корзина расположены на верхнем ярусе строго над кнопками действий,
// чтобы оператор никогда не терял фокус на сумме и подтверждении.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';

/// [UI-KIT] Двухъярусная панель итогов и действий для накладных и документов склада
class AppDocumentFooter extends StatelessWidget {
  final double totalAmount;
  final String currency;
  final int? itemCount;
  final int? cartCount;
  final VoidCallback? onCartTap;
  final bool isCartOpen;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final bool isLoading;
  final bool isDestructive;
  final Widget? leading;

  const AppDocumentFooter({
    super.key,
    required this.totalAmount,
    this.currency = 'с',
    this.itemCount,
    this.cartCount,
    this.onCartTap,
    this.isCartOpen = false,
    this.primaryLabel = 'Провести',
    this.onPrimaryPressed,
    this.secondaryLabel = 'В черновик',
    this.onSecondaryPressed,
    this.cancelLabel = 'Отмена',
    this.onCancel,
    this.isLoading = false,
    this.isDestructive = false,
    this.leading,
  });

  String _formatNumber(double val) {
    final isInt = val.truncateToDouble() == val;
    final parts = (isInt ? val.toInt().toString() : val.toStringAsFixed(2)).split('.');
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    parts[0] = parts[0].replaceAllMapped(regex, (m) => '${m[1]} ');
    return parts.join('.');
  }

  Widget _buildCartButton(bool isDark) {
    final count = cartCount ?? 0;
    final color = isCartOpen
        ? Colors.white
        : (count > 0 ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext));
    final bg = isCartOpen
        ? AppColors.brandPrimary
        : (count > 0
            ? AppColors.brandPrimary.withValues(alpha: isDark ? 0.16 : 0.10)
            : (isDark ? AppColors.darkCard : AppColors.lightBg));
    final border = isCartOpen || count > 0
        ? AppColors.brandPrimary.withValues(alpha: 0.4)
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return InkWell(
      onTap: onCartTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.shoppingCart, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              '$count поз.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(width: 4),
            Icon(
              isCartOpen ? PhosphorIconsRegular.caretDown : PhosphorIconsRegular.caretUp,
              size: 12,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final topBarBg = isDark
        ? AppColors.darkCard.withValues(alpha: 0.5)
        : AppColors.lightCard.withValues(alpha: 0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─── 1. Верхний информационный ярус: Корзина и ИТОГО над кнопками ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: topBarBg,
            border: Border(top: BorderSide(color: border)),
          ),
          child: Row(
            children: [
              // Слева: счетчик строк документа
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIconsRegular.receipt,
                    size: 15,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'К оприходованию: ${itemCount ?? 0} поз.',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Справа: Кнопка корзины + ИТОГО (строго над кнопками действий)
              if (onCartTap != null) ...[
                _buildCartButton(isDark),
                const SizedBox(width: 14),
              ],
              Text(
                'ИТОГО:',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatNumber(totalAmount),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDestructive
                          ? AppColors.danger
                          : (isDark ? AppColors.darkText : AppColors.lightText),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    currency,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ─── 2. Нижний операционный ярус: Действия и селекторы ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: surfaceBg,
            border: Border(top: BorderSide(color: border)),
          ),
          child: Row(
            children: [
              // Слева: дополнительные опции (оплата, скидка и т.д.)
              if (leading != null) leading! else const Spacer(),

              // Справа: кнопки управления
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onCancel != null) ...[
                    AppGhostButton(
                      label: cancelLabel,
                      size: AppButtonSize.md,
                      onPressed: onCancel,
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (secondaryLabel != null && onSecondaryPressed != null) ...[
                    AppSecondaryButton(
                      label: secondaryLabel!,
                      size: AppButtonSize.md,
                      onPressed: onSecondaryPressed,
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (onPrimaryPressed != null)
                    isDestructive
                        ? AppDangerButton(
                            label: primaryLabel,
                            size: AppButtonSize.md,
                            isLoading: isLoading,
                            onPressed: onPrimaryPressed,
                          )
                        : AppPrimaryButton(
                            label: primaryLabel,
                            size: AppButtonSize.md,
                            isLoading: isLoading,
                            onPressed: onPrimaryPressed,
                          ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
