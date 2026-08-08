import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkCardHover : AppColors.lightBorder;
    final highlightColor = isDark ? AppColors.darkBorder : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white, // Shimmer requires an opaque child to paint over
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.itemCount = 10,
    this.itemHeight = 72.0,
    this.padding = const EdgeInsets.all(24.0),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return SkeletonLoader(
          width: double.infinity,
          height: itemHeight,
          borderRadius: 12,
        );
      },
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  final int itemCount;
  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry padding;

  const SkeletonGrid({
    super.key,
    this.itemCount = 12,
    required this.gridDelegate,
    this.padding = const EdgeInsets.all(24.0),
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: gridDelegate,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const SkeletonLoader(
          width: double.infinity,
          height: double.infinity,
          borderRadius: 16,
        );
      },
    );
  }
}
