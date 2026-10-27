// ==============================================================================
// МОДУЛЬ: Аналитика / Скелетон загрузки дашборда (AnalyticsDashboardSkeleton)
// ДОМЕН: lib/features/analytics/view/widgets/analytics_dashboard_skeleton.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';

// ── Скелетон структуры аналитического дашборда ──────────────────────────────
/// [UI-KIT] Сохраняет пространственный каркас дашборда при первом холодном запуске,
/// предотвращая резкое схлопывание экрана в одиночный спиннер (Layout Thrashing).
class AnalyticsDashboardSkeleton extends StatelessWidget {
  const AnalyticsDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isWideDesktop = MediaQuery.of(context).size.width > 1100;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final shimmerBase = isDark ? AppColors.darkBorder : AppColors.lightCardHover;
    final shimmerHighlight = isDark ? AppColors.darkCardHover : AppColors.lightCard;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
      child: Shimmer.fromColors(
        baseColor: shimmerBase,
        highlightColor: shimmerHighlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Сетка KPI карточек
            _buildKpiGridSkeleton(isWideDesktop, baseColor),
            const SizedBox(height: 14),

            // 2. Блок графиков выручки и категорий
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildCardSkeleton(height: 260, baseColor: baseColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 1,
                    child: _buildCardSkeleton(height: 260, baseColor: baseColor),
                  ),
                ],
              )
            else ...[
              _buildCardSkeleton(height: 230, baseColor: baseColor),
              const SizedBox(height: 14),
              _buildCardSkeleton(height: 230, baseColor: baseColor),
            ],
            const SizedBox(height: 14),

            // 3. Таблица X-Ray
            _buildCardSkeleton(height: 320, baseColor: baseColor),
          ],
        ),
      ),
    );
  }

  // ── Каркас сетки KPI ───────────────────────────────────────────────────────

  Widget _buildKpiGridSkeleton(bool isWide, Color baseColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isWide ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: isWide ? 104 : 84,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => _buildCardSkeleton(
            height: isWide ? 104 : 84,
            baseColor: baseColor,
          ),
        );
      },
    );
  }

  // ── Каркасная карточка с закруглёнными углами ─────────────────────────────

  Widget _buildCardSkeleton({required double height, required Color baseColor}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: AppRadii.cardRadius,
      ),
    );
  }
}
