import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';

class DuplicateWarningChip extends StatelessWidget {
  final String message;
  final VoidCallback? onOpenExisting;

  const DuplicateWarningChip({
    super.key,
    required this.message,
    this.onOpenExisting,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: AppRadii.inputRadius,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: isDark ? 0.4 : 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            PhosphorIconsRegular.warningCircle,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFB78103),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onOpenExisting != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onOpenExisting,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Открыть',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFB78103),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      PhosphorIconsRegular.arrowSquareOut,
                      size: 14,
                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFB78103),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
