import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

enum ToastType { success, error, warning, info, cart }

class AppToast {
  static void showSuccess(
    BuildContext context,
    String title, {
    String? subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, title, subtitle: subtitle, type: ToastType.success, duration: duration);
  }

  static void showError(
    BuildContext context,
    String title, {
    String? subtitle,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(context, title, subtitle: subtitle, type: ToastType.error, duration: duration);
  }

  static void showWarning(
    BuildContext context,
    String title, {
    String? subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, title, subtitle: subtitle, type: ToastType.warning, duration: duration);
  }

  static void showInfo(
    BuildContext context,
    String title, {
    String? subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, title, subtitle: subtitle, type: ToastType.info, duration: duration);
  }

  static void showCart(
    BuildContext context,
    String itemName, {
    int count = 1,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    _show(
      context,
      'Добавлено в заказ',
      subtitle: '$itemName ($count шт.)',
      type: ToastType.cart,
      duration: duration,
    );
  }

  static void showUndo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 5),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final snackBar = SnackBar(
      elevation: 0,
      backgroundColor: AppColors.transparent,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      width: 440,
      padding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: AppShadows.medium,
        ),
        child: Row(
          children: [
            Icon(PhosphorIconsRegular.cookingPot, color: AppColors.brandPrimary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                messenger.hideCurrentSnackBar();
                onUndo();
              },
              borderRadius: AppRadii.buttonRadius,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: AppRadii.buttonRadius,
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'ВЕРНУТЬ',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => messenger.hideCurrentSnackBar(),
              borderRadius: AppRadii.dialogRadius,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  PhosphorIconsRegular.x,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    messenger.showSnackBar(snackBar);
  }

  static void _show(
    BuildContext context,
    String title, {
    String? subtitle,
    required ToastType type,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    Color accentColor;
    IconData iconData;

    switch (type) {
      case ToastType.success:
        accentColor = AppColors.success;
        iconData = PhosphorIconsRegular.checkCircle;
        break;
      case ToastType.error:
        accentColor = AppColors.danger;
        iconData = PhosphorIconsRegular.warningCircle;
        break;
      case ToastType.warning:
        accentColor = AppColors.warning;
        iconData = PhosphorIconsRegular.warning;
        break;
      case ToastType.cart:
        accentColor = AppColors.brandPrimary;
        iconData = PhosphorIconsRegular.shoppingCart;
        break;
      case ToastType.info:
        accentColor = AppColors.info;
        iconData = PhosphorIconsRegular.info;
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtextColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    final snackBar = SnackBar(
      elevation: 0,
      backgroundColor: AppColors.transparent,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      width: 440,
      padding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.2),
          boxShadow: AppShadows.glow(accentColor, opacity: 0.15, blur: 20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: subtextColor,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => messenger.hideCurrentSnackBar(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  PhosphorIconsRegular.x,
                  color: subtextColor,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    messenger.showSnackBar(snackBar);
  }
}
