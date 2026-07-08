import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

Widget buildSettingsHeader(String title, bool isDark) {
  return Text(
    title,
    style: AppTextStyles.h1.copyWith(
      color: isDark ? AppColors.darkText : AppColors.lightText,
      fontSize: 28,
    ),
  );
}

class SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const SettingsCard({super.key, required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final Widget trailing;

  const SettingsRow({
    super.key,
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Flexible(
            flex: 2,
            child: trailing,
          ),
        ],
      ),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  final bool isDark;

  const SettingsDivider({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}

class DropdownStub extends StatelessWidget {
  final bool isDark;
  final String value;

  const DropdownStub({super.key, required this.isDark, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            PhosphorIconsRegular.caretDown,
            size: 16,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ],
      ),
    );
  }
}

class ButtonStub extends StatelessWidget {
  final bool isDark;
  final String label;
  final bool isPrimary;

  const ButtonStub({
    super.key,
    required this.isDark,
    required this.label,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.brandPrimary
            : (isDark ? AppColors.darkBg : AppColors.lightBg),
        borderRadius: BorderRadius.circular(8),
        border: isPrimary
            ? null
            : Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isPrimary
              ? Colors.white
              : (isDark ? AppColors.darkText : AppColors.lightText),
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
