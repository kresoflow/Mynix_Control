import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class OrdersSkeleton extends StatelessWidget {
  final int count;
  const OrdersSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: count,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Shimmer.fromColors(
              baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: highlightColor,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 100, height: 12, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 60, height: 16, color: Colors.white),
                      ],
                    ),
                  ),
                  Container(width: 80, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100))),
                  const SizedBox(width: 24),
                  Container(width: 60, height: 24, color: Colors.white),
                  const SizedBox(width: 16),
                  Container(width: 24, height: 24, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
