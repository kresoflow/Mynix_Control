import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';

class ReceiveDocumentAutocompleteOptionsView extends StatelessWidget {
  final Iterable<Ingredient> options;
  final AutocompleteOnSelected<Ingredient> onSelected;

  const ReceiveDocumentAutocompleteOptionsView({
    super.key,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        child: Container(
          width: 320,
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, optIndex) {
              final option = options.elementAt(optIndex);
              return ListTile(
                dense: true,
                title: Text(
                  option.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  '${option.unit} • ${option.costPerUnit} TJS',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    fontSize: 11,
                  ),
                ),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  }
}
