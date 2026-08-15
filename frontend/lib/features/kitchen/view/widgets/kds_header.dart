import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/kitchen/bloc/kitchen_bloc.dart';
import 'package:mynix_frontend/features/kitchen/bloc/kitchen_event.dart';

class KdsHeader extends StatelessWidget {
  final int activeCount;
  final bool isConnected;
  final bool isDark;

  const KdsHeader({
    super.key,
    required this.activeCount,
    required this.isConnected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Text(
                'КУХНЯ: ЗАКАЗЫ',
                style: AppTextStyles.h1.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isConnected ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? PhosphorIconsRegular.wifiHigh : PhosphorIconsRegular.wifiSlash,
                  color: isConnected ? AppColors.success : AppColors.danger,
                  size: 20,
                ),
              ),
              IconButton(
                icon: Icon(
                  PhosphorIconsRegular.arrowsClockwise,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
                onPressed: () {
                  context.read<KitchenBloc>().add(FetchActiveOrders());
                },
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$activeCount Активных',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
