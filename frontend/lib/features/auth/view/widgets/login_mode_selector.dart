// ==============================================================================
// МОДУЛЬ: Авторизация / Переключатель режима входа
// ДОМЕН: lib/features/auth/view/widgets/login_mode_selector.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Таб-переключатель между входом по PIN и по логину/паролю:
// 1. Адаптивная анимация переключения с поддержкой темной/светлой темы.
// 2. Использование токенов AppColors и AppRadii.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';

class LoginModeSelector extends StatelessWidget {
  final bool isPinMode;
  final bool isDark;
  final ValueChanged<bool> onModeChanged;

  const LoginModeSelector({
    super.key,
    required this.isPinMode,
    required this.isDark,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadii.radiusXl,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'PIN-код',
              icon: PhosphorIconsRegular.hash,
              isSelected: isPinMode,
              onTap: () => onModeChanged(true),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'Логин и пароль',
              icon: PhosphorIconsRegular.user,
              isSelected: !isPinMode,
              onTap: () => onModeChanged(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.inputRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : AppColors.transparent,
          borderRadius: AppRadii.inputRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.pureWhite
                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.pureWhite
                      : (isDark ? AppColors.darkText : AppColors.lightText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
