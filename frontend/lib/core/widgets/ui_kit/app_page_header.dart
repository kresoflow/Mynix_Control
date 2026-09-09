import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? breadcrumbs;
  final List<Widget>? kpiChips;
  final Widget? searchField;
  final Widget? viewSwitcher;
  final List<Widget>? actions;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs,
    this.kpiChips,
    this.searchField,
    this.viewSwitcher,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Title & Subtitle / Breadcrumbs
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: breadcrumbs!,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      title,
                      style: AppTextStyles.h2.copyWith(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && !isMobile) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Center / Right Actions
              if (!isMobile) ...[
                if (kpiChips != null && kpiChips!.isNotEmpty) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: kpiChips!.map((chip) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: chip,
                    )).toList(),
                  ),
                  const SizedBox(width: 12),
                ],
                if (searchField != null) ...[
                  searchField!,
                  const SizedBox(width: 8),
                ],
                if (viewSwitcher != null) ...[
                  viewSwitcher!,
                  const SizedBox(width: 8),
                ],
                if (actions != null && actions!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!.map((act) => Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: act,
                    )).toList(),
                  ),
              ],
            ],
          ),

          // Mobile Secondary Toolbar
          if (isMobile && (actions != null || searchField != null || kpiChips != null)) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (searchField != null) ...[
                    searchField!,
                    const SizedBox(width: 8),
                  ],
                  if (kpiChips != null) ...[
                    ...kpiChips!.map((chip) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: chip,
                    )),
                  ],
                  if (actions != null) ...[
                    ...actions!.map((act) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: act,
                    )),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
