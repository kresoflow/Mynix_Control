// ==============================================================================
// МОДУЛЬ: Склад / Вкладка «Остатки» (Warehouse Stock Tab)
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/stock_tab.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/skeleton_loader.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document_dialog.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_capital_chart_card.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_category_header.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_item_row.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_low_inventory_widget.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_metrics_header.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_pill_filters.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_subcategory_header.dart';
import 'package:kreso_frontend/features/pos/models/menu_category.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ─── 1. Виджет вкладки остатков склада ───────────────────────────────────────

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
  String _searchQuery = '';
  bool _isExpandedAll = false;
  final Map<String, bool> _expandedCategories = {};
  final Map<String, bool> _expandedSubcategories = {};

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
  }

  // ─── 2. Обработчики действий (Handlers) ────────────────────────────────────

  void _toggleExpandAll() {
    setState(() {
      _isExpandedAll = !_isExpandedAll;
      for (final key in _expandedCategories.keys) {
        _expandedCategories[key] = _isExpandedAll;
      }
      for (final key in _expandedSubcategories.keys) {
        _expandedSubcategories[key] = _isExpandedAll;
      }
    });
  }

  void _onCategoryExpansionChanged(String category, bool isExpanded) {
    setState(() {
      _expandedCategories[category] = isExpanded;
      if (!isExpanded) _isExpandedAll = false;
    });
  }

  void _onSubcategoryExpansionChanged(String subKey, bool isExpanded) {
    setState(() {
      _expandedSubcategories[subKey] = isExpanded;
    });
  }

  void _openReceiveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<IngredientBloc>(),
        child: const ReceiveDocumentDialog(),
      ),
    );
  }

  // ─── 3. Иерархическая группировка категорий ────────────────────────────────

  /// Определяет путь категории (Корневая папка и Подпапка) для позиции склада.
  (String rootName, String subName) _getCategoryHierarchy(
    Ingredient item,
    List<MenuCategory> allCategories,
  ) {
    if (item.categoryId == null) {
      return (item.categoryName ?? 'Без категории', '');
    }

    final currentCat = allCategories.where((c) => c.id == item.categoryId).firstOrNull;
    if (currentCat == null) {
      return (item.categoryName ?? 'Без категории', '');
    }

    if (currentCat.parentId == null) {
      return (currentCat.name, '');
    }

    var root = allCategories.where((c) => c.id == currentCat.parentId).firstOrNull;
    while (root?.parentId != null) {
      final parent = allCategories.where((c) => c.id == root!.parentId).firstOrNull;
      if (parent == null) break;
      root = parent;
    }

    return (root?.name ?? currentCat.name, currentCat.name);
  }

  // ─── 4. Построение интерфейса ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<IngredientBloc, IngredientState>(
      builder: (context, state) {
        if (state is IngredientLoading) {
          return const SkeletonList();
        } else if (state is IngredientError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(PhosphorIconsRegular.warningCircle, size: 48, color: AppColors.danger),
                const SizedBox(height: 12),
                Text('Не удалось загрузить остатки склада', style: AppTextStyles.h3),
                const SizedBox(height: 6),
                Text(state.message.replaceAll('Exception: ', ''), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.read<IngredientBloc>().add(const LoadIngredients()),
                  icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 16),
                  label: const Text('Повторить попытку'),
                ),
              ],
            ),
          );
        } else if (state is! IngredientLoaded) {
          return const SizedBox.shrink();
        }

        final catState = context.watch<CategoryBloc>().state;
        final List<MenuCategory> allCategories = catState is CategoryLoaded ? catState.categories : [];

        final filtered = state.ingredients.where((item) {
          if (item.isArchived) return false;
          if (item.categoryId != null) {
            final cat = allCategories.where((c) => c.id == item.categoryId).firstOrNull;
            if (cat != null && cat.isArchived) return false;
          }
          final isRetail = item.attributes != null && item.attributes!['is_retail'] == true;
          if (_filter == 'retail' && !isRetail) return false;
          if (_filter == 'raw' && isRetail) return false;
          if (_searchQuery.isNotEmpty) {
            final name = item.name.toLowerCase();
            final barcode = item.barcode?.toLowerCase() ?? '';
            final sku = item.sku?.toLowerCase() ?? '';
            return name.contains(_searchQuery) || barcode.contains(_searchQuery) || sku.contains(_searchQuery);
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'Ничего не найдено по запросу "$_searchQuery"'
                  : 'Нет товаров в этой категории.',
              style: AppTextStyles.body.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSubtext
                    : AppColors.lightSubtext,
              ),
            ),
          );
        }

        double totalCapital = 0;
        double potentialRevenue = 0;
        int lowStockCount = 0;
        final List<Ingredient> lowStockItems = [];

        for (var item in filtered) {
          if (item.currentStock > 0) {
            totalCapital += item.currentStock * item.costPerUnit;
            potentialRevenue += item.currentStock * (item.price ?? item.costPerUnit);
          }
          if (item.isLowStock || item.currentStock <= 0) {
            lowStockCount++;
            lowStockItems.add(item);
          }
        }
        final double expectedProfit = potentialRevenue - totalCapital;

        // Группировка 2 уровней: Корневая папка -> Подпапки -> Позиции
        final Map<String, Map<String, List<Ingredient>>> hierarchy = {};
        final Map<String, List<Ingredient>> allRootItems = {};
        final Map<String, double> categoryCapitals = {};

        for (var item in filtered) {
          final (rootName, subName) = _getCategoryHierarchy(item, allCategories);

          hierarchy.putIfAbsent(rootName, () => {});
          hierarchy[rootName]!.putIfAbsent(subName, () => []).add(item);

          allRootItems.putIfAbsent(rootName, () => []).add(item);

          if (!_expandedCategories.containsKey(rootName)) {
            _expandedCategories[rootName] = _isExpandedAll;
          }

          final subKey = '$rootName::$subName';
          if (!_expandedSubcategories.containsKey(subKey)) {
            _expandedSubcategories[subKey] = _isExpandedAll;
          }

          if (item.currentStock > 0) {
            categoryCapitals[rootName] = (categoryCapitals[rootName] ?? 0) + (item.currentStock * item.costPerUnit);
          }
        }

        final sortedRootCategories = hierarchy.keys.toList()..sort((a, b) {
          if (a == 'Без категории') return 1;
          if (b == 'Без категории') return -1;
          return a.compareTo(b);
        });

        // Построение плоского списка элементов с иерархией для виртуализации
        final List<dynamic> flatList = [];
        for (final rootCategory in sortedRootCategories) {
          final items = allRootItems[rootCategory]!;
          final subMap = hierarchy[rootCategory]!;
          final isRootExpanded = _searchQuery.isNotEmpty || (_expandedCategories[rootCategory] ?? false);

          flatList.add({
            'type': 'header',
            'categoryName': rootCategory,
            'items': items,
            'isExpanded': isRootExpanded,
          });

          if (isRootExpanded) {
            final hasRealSubcategories = subMap.keys.any((k) => k.isNotEmpty);

            if (hasRealSubcategories) {
              final sortedSubcategories = subMap.keys.toList()..sort((a, b) {
                if (a.isEmpty) return -1;
                if (b.isEmpty) return 1;
                return a.compareTo(b);
              });

              for (final subName in sortedSubcategories) {
                final subItems = subMap[subName]!;
                final subKey = '$rootCategory::$subName';
                final isSubExpanded = _searchQuery.isNotEmpty || (_expandedSubcategories[subKey] ?? false);

                if (subName.isNotEmpty) {
                  flatList.add({
                    'type': 'subcategory_header',
                    'subcategoryName': subName,
                    'subKey': subKey,
                    'items': subItems,
                    'isExpanded': isSubExpanded,
                  });

                  if (isSubExpanded) {
                    for (int i = 0; i < subItems.length; i++) {
                      flatList.add({
                        'type': 'item',
                        'item': subItems[i],
                        'isLast': i == subItems.length - 1,
                      });
                    }
                  }
                } else {
                  for (int i = 0; i < subItems.length; i++) {
                    flatList.add({
                      'type': 'item',
                      'item': subItems[i],
                      'isLast': i == subItems.length - 1,
                    });
                  }
                }
              }
            } else {
              for (int i = 0; i < items.length; i++) {
                flatList.add({
                  'type': 'item',
                  'item': items[i],
                  'isLast': i == items.length - 1,
                });
              }
            }
          }
        }

        final itemsList = ListView.builder(
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
            } else if (data['type'] == 'subcategory_header') {
              return StockSubcategoryHeader(
                subcategoryName: data['subcategoryName'],
                items: List<Ingredient>.from(data['items'] ?? []),
                isExpanded: data['isExpanded'],
                onTap: () => _onSubcategoryExpansionChanged(
                  data['subKey'],
                  !data['isExpanded'],
                ),
              );
            } else {
              return StockItemRow(
                item: data['item'],
                isLast: data['isLast'] ?? false,
              );
            }
          },
        );

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 1050;

                  if (!isDesktop) {
                    return Column(
                      children: [
                        StockPillFilters(
                          currentFilter: _filter,
                          onFilterChanged: (val) => setState(() => _filter = val),
                          isExpandedAll: _isExpandedAll,
                          onToggleExpandAll: _toggleExpandAll,
                          onSearchChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                        ),
                        Expanded(child: itemsList),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 65,
                        child: Column(
                          children: [
                            StockPillFilters(
                              currentFilter: _filter,
                              onFilterChanged: (val) => setState(() => _filter = val),
                              isExpandedAll: _isExpandedAll,
                              onToggleExpandAll: _toggleExpandAll,
                              onSearchChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                            ),
                            Expanded(child: itemsList),
                          ],
                        ),
                      ),
                      Container(
                        width: 350,
                        padding: const EdgeInsets.only(right: 24, top: 8, bottom: 16),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              StockCapitalChartCard(
                                categoryCapitals: categoryCapitals,
                                totalCapital: totalCapital,
                                key: ValueKey(totalCapital),
                              ),
                              const SizedBox(height: 14),
                              StockLowInventoryWidget(
                                lowStockItems: lowStockItems,
                                onReceiveTap: () => _openReceiveDialog(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
