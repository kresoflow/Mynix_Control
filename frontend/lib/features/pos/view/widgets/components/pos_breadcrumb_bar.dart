import 'package:flutter/material.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import 'package:retail_os_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PosBreadcrumbBar extends StatelessWidget {
  final List<dynamic> history;
  final VoidCallback? onBack;
  final VoidCallback onRoot;
  final ValueChanged<int> onCrumb;

  const PosBreadcrumbBar({
    super.key,
    required this.history,
    required this.onBack,
    required this.onRoot,
    required this.onCrumb,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(PhosphorIconsRegular.caretLeft, size: 16),
              color: AppColors.darkSubtext,
              onPressed: onBack,
              tooltip: 'Назад',
            ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onRoot,
                    child: Text(
                      'Меню',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: history.isEmpty
                            ? AppColors.brandPrimary
                            : AppColors.darkSubtext,
                      ),
                    ),
                  ),
                  for (int i = 0; i < history.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(PhosphorIconsRegular.caretRight,
                          size: 16, color: AppColors.darkSubtext),
                    ),
                    GestureDetector(
                      onTap: i == history.length - 1 ? null : () => onCrumb(i),
                      child: Text(
                        history[i].name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: i == history.length - 1
                              ? AppColors.brandPrimary
                              : AppColors.darkSubtext,
                          fontWeight: i == history.length - 1
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
