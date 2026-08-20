import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/theme/app_logo_base64.dart';
import 'package:mynix_frontend/core/theme/theme_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';
import 'package:mynix_frontend/features/pos/view/widgets/sync_status_badge.dart';

class MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onOpenDrawer;

  const MobileAppBar({super.key, required this.onOpenDrawer});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              PhosphorIconsRegular.list,
              color: isDark ? AppColors.darkText : AppColors.lightText,
              size: 22,
            ),
            onPressed: onOpenDrawer,
          ),
          const SizedBox(width: 4),
          Image.memory(
            AppLogoData.bytes,
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final tenantName = authState is AuthAuthenticated && authState.tenantName.isNotEmpty
                    ? authState.tenantName
                    : 'Kreso Flow';
                return Text(
                  tenantName,
                  style: AppTextStyles.h3.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
          const SyncStatusBadge(),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              isDark ? PhosphorIconsRegular.sun : PhosphorIconsRegular.moon,
              size: 20,
            ),
            onPressed: () => context.read<ThemeBloc>().add(ToggleThemeMode()),
          ),
        ],
      ),
    );
  }
}
