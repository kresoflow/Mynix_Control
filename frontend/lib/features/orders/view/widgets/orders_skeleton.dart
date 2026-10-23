import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';

class OrdersSkeleton extends StatelessWidget {
  final int count;
  const OrdersSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final baseColor = isDark ? AppColors.darkBorder : AppColors.lightCardHover;
    final highlightColor = isDark ? AppColors.darkSurface : AppColors.lightCard;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: count,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: AppRadii.radiusLg,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 100, height: 12, color: AppColors.pureWhite),
                        const SizedBox(height: 8),
                        Container(width: 60, height: 16, color: AppColors.pureWhite),
                      ],
                    ),
                  ),
                  Container(width: 80, height: 24, decoration: const BoxDecoration(color: AppColors.pureWhite, borderRadius: AppRadii.maxRadius)),
                  const SizedBox(width: 24),
                  Container(width: 60, height: 24, color: AppColors.pureWhite),
                  const SizedBox(width: 16),
                  Container(width: 24, height: 24, color: AppColors.pureWhite),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
