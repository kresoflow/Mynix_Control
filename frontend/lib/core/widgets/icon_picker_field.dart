import 'package:flutter/material.dart';
import 'package:retail_os_frontend/core/utils/icon_helper.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import 'package:retail_os_frontend/core/theme/app_text_styles.dart';
import 'package:retail_os_frontend/core/theme/app_theme.dart';

class IconPickerField extends StatelessWidget {
  final String? selectedIcon;
  final ValueChanged<String?> onIconSelected;

  const IconPickerField({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Выберите иконку',
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: IconHelper.availableIcons.length + 1, // +1 for "No icon"
                  itemBuilder: (ctx, index) {
                    if (index == 0) {
                      return InkWell(
                        onTap: () {
                          onIconSelected(null);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedIcon == null
                                  ? AppColors.brandPrimary
                                  : Colors.grey.withOpacity(0.3),
                              width: selectedIcon == null ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.close, color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    final iconName = IconHelper.availableIcons[index - 1];
                    final isSelected = selectedIcon == iconName;
                    return InkWell(
                      onTap: () {
                        onIconSelected(iconName);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.brandPrimary.withOpacity(0.1) : null,
                          border: Border.all(
                            color: isSelected ? AppColors.brandPrimary : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: IconHelper.buildIcon(
                            iconName,
                            size: 28,
                            color: isSelected ? AppColors.brandPrimary : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Иконка',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (selectedIcon != null) ...[
                  IconHelper.buildIcon(selectedIcon, color: AppColors.brandPrimary),
                  const SizedBox(width: 12),
                ],
                Text(
                  selectedIcon != null ? 'Иконка выбрана' : 'Без иконки',
                  style: TextStyle(
                    color: selectedIcon != null ? null : Colors.grey,
                  ),
                ),
              ],
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
