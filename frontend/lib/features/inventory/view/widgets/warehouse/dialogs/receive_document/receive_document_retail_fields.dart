import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add/bulk_input_decoration.dart';
import 'receipt_row_data.dart';

class ReceiveDocumentRetailFields extends StatelessWidget {
  final ReceiptRowData item;
  final VoidCallback onFlavorSubmitted;
  final VoidCallback onVolumeSubmitted;

  const ReceiveDocumentRetailFields({
    super.key,
    required this.item,
    required this.onFlavorSubmitted,
    required this.onVolumeSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        const SizedBox(width: 6),
        SizedBox(
          width: 78,
          height: 40,
          child: TextFormField(
            controller: item.flavorController,
            focusNode: item.flavorFocusNode,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontSize: 13,
            ),
            decoration: buildBulkInputDecoration(context, 'Вкус'),
            onFieldSubmitted: (_) => onFlavorSubmitted(),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 48,
          height: 40,
          child: TextFormField(
            controller: item.volumeController,
            focusNode: item.volumeFocusNode,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontSize: 13,
            ),
            decoration: buildBulkInputDecoration(context, '0.5'),
            onFieldSubmitted: (_) => onVolumeSubmitted(),
          ),
        ),
      ],
    );
  }
}
