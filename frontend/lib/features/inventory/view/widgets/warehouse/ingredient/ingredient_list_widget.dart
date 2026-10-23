import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/dialogs/create_ingredient_dialog.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/catalog_deletion_dialogs.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';


class IngredientListWidget extends StatefulWidget {
  final List<Ingredient> filteredIngredients;
  final CategoryState catState;
  final int? selectedCategoryId;
  final bool isManageMode;
  final Set<int> selectedIngredients;
  final String currency;
  final ValueChanged<Set<int>> onSelectedIngredientsChanged;

  const IngredientListWidget({
    super.key,
    required this.filteredIngredients,
    required this.catState,
    required this.selectedCategoryId,
    required this.isManageMode,
    required this.selectedIngredients,
    required this.currency,
    required this.onSelectedIngredientsChanged,
  });

  @override
  State<IngredientListWidget> createState() => _IngredientListWidgetState();
}

class _IngredientListWidgetState extends State<IngredientListWidget> {
  final Map<String, bool> _expandedCategories = {};

  void _toggleCategory(String category) {
    setState(() {
      _expandedCategories[category] = !(_expandedCategories[category] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filteredIngredients.isEmpty) {
      return const Center(child: Text('В этой категории пусто'));
    }
    
    final grouped = <String, List<Ingredient>>{};
    if (widget.selectedCategoryId == null) {
      for (var item in widget.filteredIngredients) {
        final cat = widget.catState is CategoryLoaded 
          ? (widget.catState as CategoryLoaded).categories.where((c) => c.id == item.categoryId).firstOrNull?.name ?? 'Без категории'
          : 'Без категории';
        grouped.putIfAbsent(cat, () => []).add(item);
      }
    } else {
      grouped[''] = widget.filteredIngredients;
    }
    
    final sortedKeys = grouped.keys.toList()..sort();

    // Создаем плоский список
    final List<dynamic> flatList = [];
    for (final catName in sortedKeys) {
      final items = grouped[catName]!;
      
      if (catName.isNotEmpty) {
        final isExpanded = _expandedCategories[catName] ?? false;
        flatList.add({
          'type': 'header',
          'categoryName': catName,
          'isExpanded': isExpanded,
        });
        
        if (isExpanded) {
          flatList.addAll(items.map((item) => {'type': 'item', 'item': item, 'hasDivider': true}));
        }
      } else {
        // Если выбрана конкретная категория (catName пустой)
        flatList.addAll(items.map((item) => {'type': 'item', 'item': item, 'hasDivider': item != items.first}));
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: AppRadii.radiusLg,
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
          boxShadow: AppShadows.card,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.radiusLg,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: flatList.length,
            itemBuilder: (context, index) {
              final data = flatList[index];
              
              if (data['type'] == 'header') {
                final catName = data['categoryName'] as String;
                final isExpanded = data['isExpanded'] as bool;
                return Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    onTap: () => _toggleCategory(catName),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              catName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              PhosphorIconsRegular.caretDown,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                final item = data['item'] as Ingredient;
                final hasDivider = data['hasDivider'] as bool;
                final isLowStock = item.isLowStock;
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasDivider) const Divider(height: 1),
                    Material(
                      color: widget.selectedIngredients.contains(item.id) 
                          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) 
                          : AppColors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: widget.isManageMode
                          ? Checkbox(
                              value: widget.selectedIngredients.contains(item.id),
                              onChanged: (val) {
                                final newSelected = Set<int>.from(widget.selectedIngredients);
                                if (val == true) {
                                  newSelected.add(item.id);
                                } else {
                                  newSelected.remove(item.id);
                                }
                                widget.onSelectedIngredientsChanged(newSelected);
                              },
                            )
                          : () {
                              final cat = widget.catState is CategoryLoaded ? (widget.catState as CategoryLoaded).categories.where((c) => c.id == item.categoryId).firstOrNull : null;
                              final subtextColor = Theme.of(context).brightness == Brightness.dark ? AppColors.darkSubtext : AppColors.lightSubtext;
                              return IconHelper.buildIcon(cat?.icon, color: isLowStock ? AppColors.danger : subtextColor);
                            }(),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                borderRadius: AppRadii.radiusXs,
                              ),
                              child: Text(
                                item.displayCode,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Flexible(child: Text(item.name, style: const TextStyle(fontSize: 16))),
                            if (item.categoryId == null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: AppRadii.radiusXs,
                                ),
                                child: const Text(
                                  'Без категории',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text('Остаток: ${UnitFormatter.formatAmount(item.currentStock, item.unit)} | Алерт: ${UnitFormatter.formatAmount(item.minStockAlert, item.unit)}'),
                        trailing: widget.isManageMode ? null : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item.costPerUnit.toInt()} ${widget.currency} / ${UnitFormatter.format(item.unit)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                PhosphorIconsRegular.dotsThreeVertical,
                                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              ),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  showAddIngredientDialog(context, itemToEdit: item);
                                } else if (val == 'delete') {
                                  CatalogDeletionDialogs.confirmDeleteIngredient(context, item);
                                } else if (val == 'restore') {
                                  context.read<IngredientBloc>().add(RestoreIngredient(item.id));
                                }
                              },
                              itemBuilder: (ctx) => item.isArchived
                                  ? [
                                      const PopupMenuItem(
                                        value: 'restore',
                                        child: Row(
                                          children: [
                                            Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 16),
                                            SizedBox(width: 8),
                                            Text('Восстановить'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.danger),
                                            SizedBox(width: 8),
                                            Text('Удалить навсегда', style: TextStyle(color: AppColors.danger)),
                                          ],
                                        ),
                                      ),
                                    ]
                                  : [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(PhosphorIconsRegular.pencilSimple, size: 16),
                                            SizedBox(width: 8),
                                            Text('Редактировать'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(PhosphorIconsRegular.archive, size: 16, color: AppColors.danger),
                                            SizedBox(width: 8),
                                            Text('Архивировать', style: TextStyle(color: AppColors.danger)),
                                          ],
                                        ),
                                      ),
                                    ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
