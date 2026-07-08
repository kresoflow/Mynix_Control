import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/analytics/models/dashboard_data.dart';

class LowStockAlertsWidget extends StatelessWidget {
  final List<LowStockAlert> alerts;

  const LowStockAlertsWidget({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final hasAlerts = alerts.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAlerts 
              ? AppColors.danger.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: hasAlerts ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: hasAlerts 
                ? AppColors.danger.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: hasAlerts ? 24 : 10,
            offset: hasAlerts ? const Offset(0, 12) : const Offset(0, 4),
            spreadRadius: hasAlerts ? 2 : 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (hasAlerts ? AppColors.danger : AppColors.success).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: hasAlerts ? [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ] : [],
                ),
                child: Icon(
                  hasAlerts ? PhosphorIconsRegular.warning : PhosphorIconsRegular.checkCircle,
                  color: hasAlerts ? AppColors.danger : AppColors.success,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  hasAlerts
                      ? 'Внимание! Заканчиваются запасы'
                      : 'Запасы в норме',
                  style: AppTextStyles.h2.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (hasAlerts) ...[
            const SizedBox(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alerts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildAlertItem(alerts[index], isDark),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertItem(LowStockAlert alert, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.04),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    alert.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'Остаток: ${alert.currentStock.toStringAsFixed(1)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
