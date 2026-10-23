import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';

InputDecoration buildBulkInputDecoration(
  BuildContext context,
  String label, {
  bool isHintOnly = false,
  Widget? suffixIcon,
  String? suffixText,
  EdgeInsetsGeometry? contentPadding,
}) {
  return InputDecoration(
    labelText: isHintOnly ? null : label,
    hintText: isHintOnly ? label : null,
    hintStyle: TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      fontSize: 13,
    ),
    labelStyle: TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      fontSize: 13,
    ),
    suffixIcon: suffixIcon,
    suffixText: suffixText,
    suffixStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    ),
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    border: OutlineInputBorder(
      borderRadius: AppRadii.inputRadius,
      borderSide: isHintOnly
          ? BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: 1,
            )
          : BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadii.inputRadius,
      borderSide: isHintOnly
          ? BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: 1,
            )
          : BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadii.inputRadius,
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
        width: 1.5,
      ),
    ),
    contentPadding: contentPadding ??
        (isHintOnly
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
  );
}
