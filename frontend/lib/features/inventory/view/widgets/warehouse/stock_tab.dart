import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/stock/stock_pill_filters.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/stock/stock_category_header.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/stock/stock_item_row.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/stock/stock_metrics_header.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'package:mynix_frontend/core/widgets/skeleton_loader.dart';

class StockTab extends StatefulWidget {
  final String filter;
  const StockTab({super.key, required this.filter});

  @override
  State<StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<StockTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late String _filter;
  bool _isExpandedAll = false;
  final Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
  }

  void _toggleExpandAll() {
    setState(() {
      _isExpandedAll = !_isExpandedAll;
      for (final key in _expandedCategories.keys) {
        _expandedCategories[key] = _isExpandedAll;
      }
    });
  }

  void _onCategoryExpansionChanged(String category, bool isExpanded) {
    setState(() {
      _expandedCategories[category] = isExpanded;
      if (!isExpanded) {
        _isExpandedAll = false;
      }
    });
  }

  String _getRootCategoryName(Ingredient item, List<MenuCategory> allCategories) {
    if (item.categoryId == null) return item.categoryName ?? 'Без категории';
    var currentCat = allCategories.where((c) => c.id == item.categoryId).firstOrNull;
    if (currentCat == null) return item.categoryName ?? 'Без категории';

    while (currentCat?.parentId != null) {
      final parent = allCategories.where((c) => c.id == currentCat!.parentId).firstOrNull;
      if (parent == null) break;
      currentCat = parent;
    }
    return currentCat?.name ?? item.categoryName ?? 'Без категории';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        StockPillFilters(
          currentFilter: _filter,
          onFilterChanged: (val) => setState(() => _filter = val),
          isExpandedAll: _isExpandedAll,
          onToggleExpandAll: _toggleExpandAll,
        ),
        Expanded(
          child: BlocBuilder<IngredientBloc, IngredientState>(
            builder: (context, state) {
              if (state is IngredientLoading) {
                return const SkeletonList();
              } else if (state is IngredientLoaded) {
                final filtered = state.ingredients.where((item) {
                  final isRetail = item.attributes != null && item.attributes!['is_retail'] == true;
                  if (_filter == 'retail') return isRetail;
                  if (_filter == 'raw') return !isRetail;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Нет товаров в этой категории.'));
                }

                double totalCapital = 0;
                double potentialRevenue = 0;
                int lowStockCount = 0;
                for (var item in filtered) {
                  if (item.currentStock > 0) {
                    totalCapital += item.currentStock * item.costPerUnit;
                    potentialRevenue += item.currentStock * (item.price ?? item.costPerUnit);
                  }
                  if (item.isLowStock || item.currentStock <= 0) {
                    lowStockCount++;
                  }
                }
                final double expectedProfit = potentialRevenue - totalCapital;

                final catState = context.watch<CategoryBloc>().state;
                List<MenuCategory> allCategories = [];
                if (catState is CategoryLoaded) {
                  allCategories = catState.categories;
                }

                final Map<String, List<Ingredient>> grouped = {};
                for (var item in filtered) {
                  final cat = _getRootCategoryName(item, allCategories);
                  if (!grouped.containsKey(cat)) {
                    grouped[cat] = [];
                    if (!_expandedCategories.containsKey(cat)) {
                      _expandedCategories[cat] = _isExpandedAll;
                    }
                  }
                  grouped[cat]!.add(item);
                }

                final sortedCategories = grouped.keys.toList()..sort((a, b) {
                  if (a == 'Без категории') return 1;
                  if (b == 'Без категории') return -1;
                  return a.compareTo(b);
                });

                final List<dynamic> flatList = [];
                for (final category in sortedCategories) {
                  final items = grouped[category]!;
                  final isExpanded = _expandedCategories[category] ?? false;

                  flatList.add({
                    'type': 'header',
                    'categoryName': category,
                    'items': items,
                    'isExpanded': isExpanded,
                  });

                  if (isExpanded) {
                    for (int i = 0; i < items.length; i++) {
                      flatList.add({
                        'type': 'item',
                        'item': items[i],
                        'isLast': i == items.length - 1,
                      });
                    }
                  }
                }

                return Column(
                  children: [
                    StockMetricsHeader(
                      totalCount: filtered.length,
                      lowStockCount: lowStockCount,
                      totalCapital: totalCapital,
                      potentialRevenue: potentialRevenue,
                      expectedProfit: expectedProfit,
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: flatList.length,
                        itemBuilder: (context, index) {
                          final data = flatList[index];
                          if (data['type'] == 'header') {
                            return StockCategoryHeader(
                              categoryName: data['categoryName'],
                              items: List<Ingredient>.from(data['items'] ?? []),
                              isExpanded: data['isExpanded'],
                              onTap: () => _onCategoryExpansionChanged(
                                data['categoryName'],
                                !data['isExpanded'],
                              ),
                            );
                          } else {
                            return StockItemRow(
                              item: data['item'],
                              isLast: data['isLast'],
                            );
                          }
                        },
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
