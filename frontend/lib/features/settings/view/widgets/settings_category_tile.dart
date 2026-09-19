import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_nav_tile.dart';

class SettingsCategory {
  final IconData icon;
  final String title;

  const SettingsCategory(this.icon, this.title);
}

class SettingsCategoryTile extends StatelessWidget {
  final SettingsCategory category;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const SettingsCategoryTile({
    super.key,
    required this.category,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppNavTile(
      title: category.title,
      icon: category.icon,
      isSelected: isSelected,
      size: AppNavTileSize.lg,
      onTap: onTap,
    );
  }
}
