import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_segmented_tab.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add/bulk_add_category_selector.dart';

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
    required this.selectedParentId,
    required this.selectedChildId,
    required this.onParentChanged,
    required this.onChildChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsRegular.magicWand, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Умное создание',
                style: AppTextStyles.h3.copyWith(color: AppColors.info, fontSize: 14),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Новые названия будут автоматически созданы в указанной категории.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.info),
                ),
              ),
              AppSegmentedTab<int>(
                items: const [
                  AppSegmentedTabItem(value: 1, label: 'Витрина'),
                  AppSegmentedTabItem(value: 2, label: 'Сырье'),
                ],
                selectedValue: tabIndex,
                onValueChanged: onTabChanged,
                height: 36,
                isCompact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          BulkAddCategorySelector(
            tabIndex: tabIndex,
            selectedParentId: selectedParentId,
            selectedChildId: selectedChildId,
            onParentChanged: onParentChanged,
            onChildChanged: onChildChanged,
          ),
        ],
      ),
    );
  }
}
