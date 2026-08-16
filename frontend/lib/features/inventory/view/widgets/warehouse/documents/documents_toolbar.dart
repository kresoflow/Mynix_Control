import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';

class DocumentsToolbar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onReceiveDocument;
  final VoidCallback onWriteOff;
  final VoidCallback onBlindInventory;

  const DocumentsToolbar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onReceiveDocument,
    required this.onWriteOff,
    required this.onBlindInventory,
  });

  Widget _buildPill(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedFilter == value;

    return GestureDetector(
      onTap: () => onFilterChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBg : AppColors.lightBg),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.brandPrimary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Wrap(
            spacing: 8.0,
            children: [
              _buildPill(context, 'Все', 'all'),
              _buildPill(context, 'Приходы', 'receipt'),
              _buildPill(context, 'Списания', 'write_off'),
              _buildPill(context, 'Инвентаризации', 'inventory'),
            ],
          ),
          const Spacer(),
          AppPrimaryButton(
            label: 'Оформить приход',
            icon: PhosphorIconsRegular.truck,
            onPressed: onReceiveDocument,
          ),
          const SizedBox(width: 8),
          AppGhostButton(
            label: 'Списание',
            icon: PhosphorIconsRegular.shoppingCart,
            onPressed: onWriteOff,
          ),
          const SizedBox(width: 8),
          AppGhostButton(
            label: 'Инвентаризация',
            icon: PhosphorIconsRegular.clipboardText,
            onPressed: onBlindInventory,
          ),
        ],
      ),
    );
  }
}
