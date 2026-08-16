import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StockCategoryHeader extends StatelessWidget {
  final String categoryName;
  final List<Ingredient> items;
  final bool isExpanded;
  final VoidCallback onTap;

  const StockCategoryHeader({
    super.key,
    required this.categoryName,
    required this.items,
    required this.isExpanded,
    required this.onTap,
  });

  IconData _getSmartFallbackIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('мясо') || lower.contains('птиц') || lower.contains('рыб') || lower.contains('фарш')) {
      return PhosphorIconsRegular.bone;
    }
    if (lower.contains('напит') || lower.contains('бар') || lower.contains('сок') || lower.contains('вода')) {
      return PhosphorIconsRegular.brandy;
    }
    if (lower.contains('хлеб') || lower.contains('выпеч') || lower.contains('булк')) {
      return PhosphorIconsRegular.bread;
    }
    if (lower.contains('овощ') || lower.contains('фрукт') || lower.contains('зелен')) {
      return PhosphorIconsRegular.plant;
    }
    if (lower.contains('соус') || lower.contains('масл') || lower.contains('специ')) {
      return PhosphorIconsRegular.drop;
    }
    return PhosphorIconsRegular.folderSimple;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double totalCapital = 0;
    int lowStockCount = 0;
    for (var item in items) {
      if (item.currentStock > 0) {
        totalCapital += item.currentStock * item.costPerUnit;
      }
      if (item.isLowStock || item.currentStock <= 0) {
        lowStockCount++;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: isExpanded ? 0 : 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: isExpanded
            ? const BorderRadius.vertical(top: Radius.circular(12))
            : BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? AppColors.brandPrimary.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: isExpanded
              ? const BorderRadius.vertical(top: Radius.circular(12))
              : BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, catState) {
                String? iconString;
                if (catState is CategoryLoaded) {
                  final rootCat = catState.categories.where((c) => c.name == categoryName).firstOrNull;
                  iconString = rootCat?.getInheritedIcon(catState.categories);
                }

                return Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? AppColors.brandPrimary.withValues(alpha: 0.15)
                            : (isDark ? AppColors.darkBg : AppColors.lightBg),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isExpanded
                              ? AppColors.brandPrimary.withValues(alpha: 0.3)
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                      ),
                      child: Center(
                        child: iconString != null && iconString.isNotEmpty
                            ? IconHelper.buildIcon(
                                iconString,
                                size: 18,
                                color: isExpanded
                                    ? AppColors.brandPrimary
                                    : (isDark ? AppColors.darkText : AppColors.lightText),
                              )
                            : Icon(
                                _getSmartFallbackIcon(categoryName),
                                size: 18,
                                color: isExpanded
                                    ? AppColors.brandPrimary
                                    : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isExpanded
                              ? AppColors.brandPrimary
                              : (isDark ? AppColors.darkText : AppColors.lightText),
                        ),
                      ),
                    ),
                    if (!isExpanded) ...[
                      if (lowStockCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                PhosphorIconsRegular.warningCircle,
                                size: 12,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$lowStockCount на исходе',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        '${items.length} поз.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Σ ${totalCapital.toCurrency(context)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        PhosphorIconsRegular.caretDown,
                        color: isExpanded
                            ? AppColors.brandPrimary
                            : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                        size: 18,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
