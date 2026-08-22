import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/app_text_field.dart';

class DocumentsToolbar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onReceiveDocument;
  final VoidCallback onWriteOff;
  final VoidCallback onBlindInventory;

  const DocumentsToolbar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.searchQuery,
    required this.onSearchChanged,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? AppColors.brandPrimary
                : (isDark ? AppColors.darkText : AppColors.lightText),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Filter pills
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPill(context, 'Все', 'all'),
            const SizedBox(width: 6),
            _buildPill(context, 'Приходы', 'receipt'),
            const SizedBox(width: 6),
            _buildPill(context, 'Списания', 'write_off'),
            const SizedBox(width: 6),
            _buildPill(context, 'Инвентаризации', 'inventory'),
          ],
        ),
        const SizedBox(width: 12),

        // Fixed comfortable width search bar without height constraint overflow
        SizedBox(
          width: 260,
          child: AppTextField(
            hintText: 'Поиск по номеру, поставщику...',
            isCompact: true,
            prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 16),
            onChanged: onSearchChanged,
          ),
        ),

        const Spacer(),

        AppPrimaryButton(
          label: 'Оформить приход',
          icon: PhosphorIconsRegular.truck,
          onPressed: onReceiveDocument,
        ),
        const SizedBox(width: 8),
        AppSecondaryButton(
          label: 'Списание',
          icon: PhosphorIconsRegular.trashSimple,
          onPressed: onWriteOff,
        ),
        const SizedBox(width: 8),
        AppSecondaryButton(
          label: 'Инвентаризация',
          icon: PhosphorIconsRegular.clipboardText,
          onPressed: onBlindInventory,
        ),
      ],
    );
  }
}
