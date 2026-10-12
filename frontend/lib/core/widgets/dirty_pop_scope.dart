import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

/// Shows a standard confirmation dialog before discarding unsaved form data.
Future<bool> showDiscardChangesDialog(
  BuildContext context, {
  String? title,
  String? message,
  String? confirmLabel,
}) async {
  return AppConfirmDialog.show(
    context: context,
    title: title ?? 'Несохраненные изменения',
    message: message ?? 'Выйти без сохранения? Все внесенные данные будут потеряны.',
    confirmLabel: confirmLabel ?? 'Сбросить и выйти',
    confirmIcon: PhosphorIconsRegular.trash,
    cancelLabel: 'Остаться',
    isDanger: true,
    icon: PhosphorIconsRegular.warning,
  );
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
