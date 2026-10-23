import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

class ShowcaseButtonSection extends StatelessWidget {
  final bool isDark;

  const ShowcaseButtonSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('1. Шкала размеров кнопок (AppButtonSize: XS, SM, MD, LG, XL)', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Строгие высоты (28, 32, 36, 44, 52px). Контраст: 100% сплошная заливка + Белый текст.',
            style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          const SizedBox(height: 16),
          _buildRow(
            'Primary:',
            (size) => AppPrimaryButton(
              label: size.name.toUpperCase(),
              icon: PhosphorIconsRegular.plus,
              size: size,
              onPressed: () => AppToast.showInfo(context, 'Кнопка ${size.name.toUpperCase()}'),
            ),
          ),
          const SizedBox(height: 12),
          _buildRow(
            'Secondary:',
            (size) => AppSecondaryButton(
              label: size.name.toUpperCase(),
              icon: PhosphorIconsRegular.gear,
              size: size,
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 12),
          _buildRow(
            'Ghost:',
            (size) => AppGhostButton(
              label: size.name.toUpperCase(),
              icon: PhosphorIconsRegular.x,
              size: size,
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 12),
          _buildRow(
            'Danger:',
            (size) => AppDangerButton(
              label: size.name.toUpperCase(),
              icon: PhosphorIconsRegular.trash,
              size: size,
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 12),
          _buildRow(
            'Loading:',
            (size) => AppPrimaryButton(
              label: size.name.toUpperCase(),
              size: size,
              isLoading: true,
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 12),
          _buildRow(
            'Disabled:',
            (size) => AppPrimaryButton(
              label: size.name.toUpperCase(),
              size: size,
              onPressed: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, Widget Function(AppButtonSize size) builder) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppButtonSize.values.map((size) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: builder(size),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
