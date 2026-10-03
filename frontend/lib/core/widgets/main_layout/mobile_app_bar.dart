// ==============================================================================
// МОДУЛЬ: Навигация / Мобильная шапка приложения (MobileAppBar)
// ДОМЕН: lib/core/widgets/main_layout/mobile_app_bar.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/theme/app_logo_base64.dart';
import 'package:kreso_frontend/features/pos/view/widgets/pos_operational_badges.dart';
import 'package:kreso_frontend/features/pos/view/widgets/sync_status_badge.dart';

// ── Мобильная шапка приложения ───────────────────────────────────────────────

class MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? location;

  const MobileAppBar({super.key, this.location});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final isPosRoute = location == null || location!.startsWith('/pos');
    final isOrdersRoute = location?.startsWith('/orders') == true;
    final showOperationalBadges = isPosRoute || isOrdersRoute;

    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Image.memory(
              AppLogoData.bytes,
              height: 26,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'Kreso Flow',
              style: AppTextStyles.h3.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (showOperationalBadges) ...[
              const PosOperationalBadges(size: 34),
              const SizedBox(width: 10),
            ],
            const SyncStatusBadge(),
          ],
        ),
      ),
    );
  }
}
