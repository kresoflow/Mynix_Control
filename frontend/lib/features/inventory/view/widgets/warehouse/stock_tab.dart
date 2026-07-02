import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/stock/stock_pill_filters.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/stock/stock_category_accordion.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';

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
  
  // Храним состояния раскрытия для каждой категории
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
      // Если хотя бы одна свернута, отключаем "Развернуть все"
      if (!isExpanded) {
        _isExpandedAll = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Column(
      children: [
        StockPillFilters(
          currentFilter: _filter,
          onFilterChanged: (val) {
            setState(() {
              _filter = val;
            });
          },
          isExpandedAll: _isExpandedAll,
          onToggleExpandAll: _toggleExpandAll,
        ),
        
        Expanded(
          child: BlocBuilder<IngredientBloc, IngredientState>(
            builder: (context, state) {
              if (state is IngredientLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is IngredientLoaded) {
                // Применяем фильтр
                final filtered = state.ingredients.where((item) {
                  final isRetail = item.attributes != null && item.attributes!['is_retail'] == true;
                  if (_filter == 'retail') return isRetail;
                  if (_filter == 'raw') return !isRetail;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Нет товаров в этой категории.'));
                }

                // Подсчет метрик
                double totalCapital = 0;
                int lowStockCount = 0;
                for (var item in filtered) {
                  if (item.currentStock > 0) {
                    totalCapital += item.currentStock * item.costPerUnit;
                  }
                  if (item.isLowStock || item.currentStock <= 0) {
                    lowStockCount++;
                  }
                }

                final catState = context.watch<CategoryBloc>().state;
                List<MenuCategory> allCategories = [];
                if (catState is CategoryLoaded) {
                  allCategories = catState.categories;
                }

                String getRootCategoryName(Ingredient item) {
                  if (item.categoryId == null) return 'Без категории';
                  var currentCat = allCategories.where((c) => c.id == item.categoryId).firstOrNull;
                  if (currentCat == null) return item.categoryName ?? 'Без категории';
                  
                  while (currentCat?.parentId != null) {
                    final parent = allCategories.where((c) => c.id == currentCat!.parentId).firstOrNull;
                    if (parent == null) break;
                    currentCat = parent;
                  }
                  return currentCat?.name ?? item.categoryName ?? 'Без категории';
                }

                // Группировка по категориям
                final Map<String, List<Ingredient>> grouped = {};
                for (var item in filtered) {
                  final cat = getRootCategoryName(item);
                  if (!grouped.containsKey(cat)) {
                    grouped[cat] = [];
                    // Инициализируем состояние развертывания, если его еще нет
                    if (!_expandedCategories.containsKey(cat)) {
                      _expandedCategories[cat] = _isExpandedAll;
                    }
                  }
                  grouped[cat]!.add(item);
                }

                // Сортировка категорий (Без категории - в конец)
                final sortedCategories = grouped.keys.toList()..sort((a, b) {
                  if (a == 'Без категории') return 1;
                  if (b == 'Без категории') return -1;
                  return a.compareTo(b);
                });

                return Column(
                  children: [
                    // Metrics Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Складской капитал',
                              value: '${totalCapital.toCurrency(context)}',
                              icon: PhosphorIconsRegular.wallet,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Позиций на исходе',
                              value: lowStockCount.toString(),
                              icon: PhosphorIconsRegular.warningCircle,
                              color: lowStockCount > 0 ? Colors.red : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Всего позиций',
                              value: filtered.length.toString(),
                              icon: PhosphorIconsRegular.package,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Grouped List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: sortedCategories.length,
                        itemBuilder: (context, index) {
                          final category = sortedCategories[index];
                          final items = grouped[category]!;
                          
                          return StockCategoryAccordion(
                            categoryName: category,
                            items: items,
                            isExpanded: _expandedCategories[category] ?? false,
                            onExpansionChanged: (val) => _onCategoryExpansionChanged(category, val),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
              return const Center(child: Text('Ошибка загрузки склада'));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
