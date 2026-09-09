import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/ui_kit/ui_kit.dart';

class ShowcaseBadgeSection extends StatelessWidget {
  final bool isDark;

  const ShowcaseBadgeSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('3. Бейджи статусов и индикаторы (AppStatusBadge & AppKpiChip)', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Семантическая индикация состояний с мягкой прозрачностью и контрастным текстом.',
            style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              AppStatusBadge(label: 'Оплачен', variant: AppBadgeVariant.success, icon: PhosphorIconsRegular.checkCircle),
              AppStatusBadge(label: 'На исходе', variant: AppBadgeVariant.warning, icon: PhosphorIconsRegular.warningCircle),
              AppStatusBadge(label: 'Долг / Ошибка', variant: AppBadgeVariant.danger, icon: PhosphorIconsRegular.xCircle),
              AppStatusBadge(label: 'В обработке', variant: AppBadgeVariant.info, icon: PhosphorIconsRegular.info),
              AppStatusBadge(label: 'Смена открыта', variant: AppBadgeVariant.brand, hasDot: true),
              AppStatusBadge(label: 'В архиве', variant: AppBadgeVariant.neutral),
            ],
          ),
        ],
      ),
    );
  }
}
