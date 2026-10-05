import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

class WriteOffMetaRow extends StatelessWidget {
  final String selectedReason;
  final List<String> reasons;
  final ValueChanged<String> onReasonChanged;
  final TextEditingController commentController;

  const WriteOffMetaRow({
    super.key,
    required this.selectedReason,
    required this.reasons,
    required this.onReasonChanged,
    required this.commentController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedReason,
                isExpanded: true,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontSize: 13,
                ),
                items: reasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) onReasonChanged(val);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: commentController,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Примечание / Комментарий (опционально)',
                hintStyle: AppTextStyles.caption.copyWith(
                  color:
                      isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
                isDense: true,
                filled: true,
                fillColor:
                    isDark ? AppColors.darkSurface : AppColors.lightSurface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
