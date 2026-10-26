// ==============================================================================
// МОДУЛЬ: Склад / Вкладка «Остатки» (Warehouse Stock Tab)
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/stock_tab.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/widgets/skeleton_loader.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document_dialog.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_category_header.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_empty_state.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_error_view.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_hierarchy_builder.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_item_row.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_metrics_header.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_pill_filters.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_side_panel.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_subcategory_header.dart';
import 'package:kreso_frontend/features/pos/models/menu_category.dart';

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
  final TextEditingController _searchController = TextEditingController();
  bool _isExpandedAll = false;
  final Map<String, bool> _expandedCategories = {};
  final Map<String, bool> _expandedSubcategories = {};

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetSearchAndFilter() {
    setState(() {
      _searchQuery = '';
      _filter = 'all';
      _searchController.clear();
    });
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

  // ─── 3. Построение интерфейса ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<IngredientBloc, IngredientState>(
      builder: (context, state) {
        if (state is IngredientLoading) {
          return const SkeletonList();
        } else if (state is IngredientError) {
          return StockErrorView(
            errorMessage: state.message,
            onRetry: () => context.read<IngredientBloc>().add(const LoadIngredients()),
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

        // [ИНВАРИАНТ] Доменная группировка категорий и расчет финансовых метрик
        final result = StockHierarchyBuilder.build(
          items: filtered,
          allCategories: allCategories,
          searchQuery: _searchQuery,
          expandedCategories: _expandedCategories,
          expandedSubcategories: _expandedSubcategories,
          isExpandedAll: _isExpandedAll,
        );

        final totalCapital = result.totalCapital;
        final potentialRevenue = result.potentialRevenue;
        final expectedProfit = potentialRevenue - totalCapital;
        final lowStockCount = result.lowStockCount;
        final lowStockItems = result.lowStockItems;
        final categoryCapitals = result.categoryCapitals;
        final flatList = result.flatList;

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

        final Widget contentWidget = flatList.isEmpty
            ? StockEmptyState(
                searchQuery: _searchQuery,
                filter: _filter,
                onReset: _resetSearchAndFilter,
              )
            : itemsList;

        final mainStockColumn = Column(
          children: [
            StockPillFilters(
              currentFilter: _filter,
              onFilterChanged: (val) => setState(() => _filter = val),
              isExpandedAll: _isExpandedAll,
              onToggleExpandAll: _toggleExpandAll,
              searchController: _searchController,
              onSearchChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
            Expanded(child: contentWidget),
          ],
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
                  if (constraints.maxWidth < 1050) {
                    return mainStockColumn;
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 65, child: mainStockColumn),
                      StockSidePanel(
                        categoryCapitals: categoryCapitals,
                        totalCapital: totalCapital,
                        lowStockItems: lowStockItems,
                        onReceiveTap: () => _openReceiveDialog(context),
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
