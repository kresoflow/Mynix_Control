// ==============================================================================
// МОДУЛЬ: Каталог / Диалог выбора сырья для добавления в техкарту
// ДОМЕН: lib/features/menu/view/widgets/catalog/recipe/dialogs/ingredient_picker_dialog.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

class IngredientPickerDialog extends StatefulWidget {
  final List<dynamic> availableIngredients;

  const IngredientPickerDialog({
    super.key,
    required this.availableIngredients,
  });

  static Future<int?> show(BuildContext context, List<dynamic> availableIngredients) {
    return showDialog<int>(
      context: context,
      builder: (ctx) => IngredientPickerDialog(availableIngredients: availableIngredients),
    );
  }

  @override
  State<IngredientPickerDialog> createState() => _IngredientPickerDialogState();
}

class _IngredientPickerDialogState extends State<IngredientPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _expandedCats = {};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    // ─── 1. Фильтрация сырья ─────────────────────────────────────────────────
    final filtered = widget.availableIngredients.where((ing) {
      if (ing.isArchived == true) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      final name = (ing.name as String? ?? '').toLowerCase();
      final code = (ing.displayCode as String? ?? '').toLowerCase();
      final cat = (ing.categoryName as String? ?? '').toLowerCase();
      return name.contains(q) || code.contains(q) || cat.contains(q);
    }).toList();

    // ─── 2. Группировка по категориям склада ────────────────────────────────
    final Map<String, List<dynamic>> grouped = {};
    for (var ing in filtered) {
      final catName = ing.categoryName ?? 'Без категории';
      grouped.putIfAbsent(catName, () => []).add(ing);
    }
    final sortedKeys = grouped.keys.toList()..sort();

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      surfaceTintColor: AppColors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
      child: Container(
        width: 520,
        height: 640,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Шапка диалога
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Выберите сырье', style: AppTextStyles.h3),
                InkWell(
                  borderRadius: AppRadii.inputRadius,
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(PhosphorIconsRegular.x, size: 20, color: subtextColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Поле поиска
            AppSearchField(
              size: AppSearchFieldSize.lg,
              controller: _searchController,
              hintText: 'Поиск сырья по названию или артикулу...',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            // Список категорий и ингредиентов
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text('Сырье не найдено', style: TextStyle(color: subtextColor)),
                    )
                  : ListView.builder(
                      itemCount: sortedKeys.length,
                      itemBuilder: (context, index) {
                        final catName = sortedKeys[index];
                        final items = grouped[catName]!;
                        final isExpanded = _searchQuery.isNotEmpty ? true : (_expandedCats[catName] ?? false);

                        return Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBg.withValues(alpha: 0.5) : AppColors.lightBg.withValues(alpha: 0.5),
                            borderRadius: AppRadii.inputRadius,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InkWell(
                                borderRadius: AppRadii.inputRadius,
                                onTap: () {
                                  setState(() {
                                    _expandedCats[catName] = !isExpanded;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$catName (${items.length})',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                        ),
                                      ),
                                      AnimatedRotation(
                                        turns: isExpanded ? 0.5 : 0.0,
                                        duration: const Duration(milliseconds: 180),
                                        child: Icon(PhosphorIconsRegular.caretDown, color: subtextColor, size: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isExpanded) ...[
                                const Divider(height: 1),
                                ...items.map((ing) {
                                  final isZero = (ing.currentStock as num? ?? 0) <= 0;
                                  return ListTile(
                                    dense: true,
                                    leading: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        borderRadius: AppRadii.radiusXs,
                                      ),
                                      child: Text(
                                        ing.displayCode,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    subtitle: Text(
                                      'Остаток: ${UnitFormatter.formatAmount(ing.currentStock, ing.unit)}',
                                      style: TextStyle(
                                        color: isZero ? AppColors.danger : AppColors.success,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Icon(
                                      PhosphorIconsRegular.plusCircle,
                                      size: 20,
                                      color: AppColors.brandPrimary,
                                    ),
                                    onTap: () => Navigator.of(context).pop(ing.id),
                                  );
                                }),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
