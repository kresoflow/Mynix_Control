import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

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
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    _show(
      context,
      'Добавлено в заказ',
      subtitle: '$itemName ($count шт.)',
      type: ToastType.cart,
      duration: duration,
    );
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
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      padding: EdgeInsets.zero,
      content: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
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
        ),
      ),
    );

    messenger.showSnackBar(snackBar);
  }
}
