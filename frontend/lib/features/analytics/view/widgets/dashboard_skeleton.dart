import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class DashboardSkeleton extends StatefulWidget {
  const DashboardSkeleton({super.key});

  @override
  State<DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<DashboardSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkCard : AppColors.lightBorder;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + (_controller.value * 0.5),
          child: child,
        );
      },
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _buildSkeletonBox(140, baseColor)),
                const SizedBox(width: 16),
                Expanded(child: _buildSkeletonBox(140, baseColor)),
              ],
            ),
            const SizedBox(height: 24),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildSkeletonBox(200, baseColor),
                        const SizedBox(height: 24),
                        _buildSkeletonBox(300, baseColor),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildSkeletonBox(250, baseColor),
                        const SizedBox(height: 24),
                        _buildSkeletonBox(200, baseColor),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildSkeletonBox(200, baseColor),
                  const SizedBox(height: 24),
                  _buildSkeletonBox(250, baseColor),
                  const SizedBox(height: 24),
                  _buildSkeletonBox(300, baseColor),
                  const SizedBox(height: 24),
                  _buildSkeletonBox(200, baseColor),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonBox(double height, Color color) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
