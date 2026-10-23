import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';

class CatalogSkeleton extends StatelessWidget {
  final bool isList;
  final int count;
  const CatalogSkeleton({super.key, this.isList = false, this.count = 8});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkBorder : AppColors.lightCardHover;
    final highlightColor = isDark ? AppColors.darkSurface : AppColors.lightCard;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    
    if (isList) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: count,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppRadii.radiusLg,
          ),
          padding: const EdgeInsets.all(12),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: AppColors.pureWhite, borderRadius: AppRadii.inputRadius),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 150, height: 16, color: AppColors.pureWhite),
                      const SizedBox(height: 8),
                      Container(width: 100, height: 12, color: AppColors.pureWhite),
                    ],
                  ),
                ),
                Container(width: 80, height: 16, color: AppColors.pureWhite),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: count,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppRadii.cardRadius,
        ),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: double.infinity, height: 14, color: AppColors.pureWhite),
                      const SizedBox(height: 8),
                      Container(width: 60, height: 12, color: AppColors.pureWhite),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
