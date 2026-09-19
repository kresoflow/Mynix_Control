import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_segmented_tab.dart';

class ReceiveDocumentSmartHeader extends StatelessWidget {
  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final int? selectedParentId;
  final int? selectedChildId;
  final ValueChanged<int?> onParentChanged;
  final ValueChanged<int?> onChildChanged;

  const ReceiveDocumentSmartHeader({
    super.key,
    required this.tabIndex,
    required this.onTabChanged,
    this.selectedParentId,
    this.selectedChildId,
    required this.onParentChanged,
    required this.onChildChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.package, color: AppColors.brandPrimary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Режим оприходования:',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Оприходование существующих карточек номенклатуры',
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
          const Spacer(),
          AppSegmentedTab<int>(
            items: const [
              AppSegmentedTabItem(value: 1, label: 'Витрина'),
              AppSegmentedTabItem(value: 2, label: 'Сырье'),
            ],
            selectedValue: tabIndex,
            onValueChanged: onTabChanged,
            height: 34,
            isCompact: true,
          ),
        ],
      ),
    );
  }
}
