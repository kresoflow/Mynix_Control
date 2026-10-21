import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/features/pos/models/cash_operation.dart';

/// 1. Переключатель типа операции (Внесение / Расход)
class CashOperationTypeSwitcher extends StatelessWidget {
  final CashOpType selectedType;
  final ValueChanged<CashOpType> onTypeChanged;

  const CashOperationTypeSwitcher({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _buildButton(CashOpType.deposit, 'Внесение', PhosphorIconsRegular.arrowDownLeft, isDark)),
          const SizedBox(width: 4),
          Expanded(child: _buildButton(CashOpType.withdrawal, 'Расход / Инкассация', PhosphorIconsRegular.arrowUpRight, isDark)),
        ],
      ),
    );
  }

  Widget _buildButton(CashOpType type, String label, IconData icon, bool isDark) {
    final isSelected = selectedType == type;
    final color = isSelected ? Colors.black : (isDark ? AppColors.darkText : AppColors.lightText);
    return InkWell(
      onTap: () => onTypeChanged(type),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}

/// 2. Баннер текущего остатка в кассе с кнопкой разблокировки PIN
class CashOperationCurrentBanner extends StatelessWidget {
  final double currentCash;
  final bool isFinancialsUnlocked;
  final VoidCallback onUnlockPin;

  const CashOperationCurrentBanner({
    super.key,
    required this.currentCash,
    required this.isFinancialsUnlocked,
    required this.onUnlockPin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsRegular.vault, size: 15, color: AppColors.brandPrimary),
              const SizedBox(width: 8),
              Text('В кассе сейчас:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkText : AppColors.lightText)),
            ],
          ),
          Row(
            children: [
              Text(
                isFinancialsUnlocked ? currentCash.toCurrency(context) : '••••',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.brandPrimary),
              ),
              if (!isFinancialsUnlocked) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onUnlockPin,
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsRegular.lockKey, size: 10, color: AppColors.brandPrimary),
                        const SizedBox(width: 3),
                        Text('PIN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.brandPrimary)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 3. Быстрые кнопки добавления сумм
class CashOperationQuickAmounts extends StatelessWidget {
  final List<double> quickAmounts;
  final ValueChanged<double> onAddAmount;

  const CashOperationQuickAmounts({
    super.key,
    required this.quickAmounts,
    required this.onAddAmount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: quickAmounts.map((q) => InkWell(
        onTap: () => onAddAmount(q),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Text('+${q.toInt()}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkText : AppColors.lightText)),
        ),
      ),).toList(),
    );
  }
}

/// 4. Список категорий в виде плашек
class CashOperationCategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CashOperationCategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 6,
      runSpacing: 5,
      children: categories.map((cat) {
        final isSel = selectedCategory == cat;
        return InkWell(
          onTap: () => onCategorySelected(cat),
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: isSel ? AppColors.brandPrimary : (isDark ? AppColors.darkCard : AppColors.lightCard),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isSel ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            child: Text(
              cat,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                color: isSel ? Colors.black : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
