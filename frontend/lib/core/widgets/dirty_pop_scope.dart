import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';

/// Shows a standard confirmation dialog before discarding unsaved form data.
Future<bool> showDiscardChangesDialog(
  BuildContext context, {
  String? title,
  String? message,
  String? confirmLabel,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => MynixDialog(
      title: title ?? 'Несохраненные изменения',
      icon: PhosphorIconsRegular.warning,
      isDestructive: true,
      width: 420,
      content: Text(
        message ?? 'Выйти без сохранения? Все внесенные данные будут потеряны.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        ),
      ),
      actions: [
        AppGhostButton(
          label: 'Остаться',
          onPressed: () => Navigator.pop(ctx, false),
        ),
        AppDangerButton(
          label: confirmLabel ?? 'Сбросить и выйти',
          icon: PhosphorIconsRegular.trash,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// A wrapper around [PopScope] that intercepts back gestures, Escape keys,
/// and barrier dismissals when [isDirty] or [isDirtyCheck] evaluates to true.
class DirtyPopScope extends StatelessWidget {
  final bool? isDirty;
  final ValueGetter<bool>? isDirtyCheck;
  final String? title;
  final String? message;
  final String? confirmLabel;
  final Widget child;

  const DirtyPopScope({
    super.key,
    this.isDirty,
    this.isDirtyCheck,
    this.title,
    this.message,
    this.confirmLabel,
    required this.child,
  });

  bool get _currentDirty => isDirtyCheck != null ? isDirtyCheck!() : (isDirty ?? false);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final dirty = _currentDirty;
        if (!dirty) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(result);
          }
          return;
        }

        final shouldPop = await showDiscardChangesDialog(
          context,
          title: title,
          message: message,
          confirmLabel: confirmLabel,
        );
        if (shouldPop && context.mounted) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(result);
          }
        }
      },
      child: child,
    );
  }
}
