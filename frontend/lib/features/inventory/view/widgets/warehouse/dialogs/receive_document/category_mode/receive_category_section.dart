// ==============================================================================
// МОДУЛЬ: Склад / Виртуализированная секция прихода товаров по категориям склада
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/category_mode/
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'receive_category_accordion.dart';
import 'receive_category_item_row.dart';
import 'receive_category_sync_adapter.dart';
import 'receive_category_toolbar.dart';

/// Секция прихода номенклатуры с плоской виртуализацией (0 мс время раскрытия).
class ReceiveCategorySection extends StatefulWidget {
  final List<Ingredient> availableIngredients;
  final bool isRetail;
  final String currency;
  final ReceiveCategorySyncAdapter adapter;

  const ReceiveCategorySection({
    super.key,
    required this.availableIngredients,
    required this.isRetail,
    required this.currency,
    required this.adapter,
  });

  @override
  State<ReceiveCategorySection> createState() => _ReceiveCategorySectionState();
}

class _ReceiveCategorySectionState extends State<ReceiveCategorySection> {
  final TextEditingController _searchController = TextEditingController();
  ReceiveCategoryFilter _activeFilter = ReceiveCategoryFilter.all;
  final Map<String, bool> _expansionMap = {};
  bool _isAllExpanded = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed != _searchQuery) {
      setState(() {
        _searchQuery = trimmed;
        _expansionMap.clear();
      });
    }
  }

  void _onFilterChanged(ReceiveCategoryFilter filter) {
    if (filter != _activeFilter) {
      setState(() {
        _activeFilter = filter;
        _expansionMap.clear();
      });
    }
  }

  void _toggleExpandAll(List<String> categories) {
    setState(() {
      _isAllExpanded = !_isAllExpanded;
      for (final cat in categories) {
        _expansionMap[cat] = _isAllExpanded;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Подсчет глобальной статистики для тулбара
    int totalDeficit = 0;
    int totalInReceipt = 0;

    for (final item in widget.availableIngredients) {
      if (item.isLowStock || item.currentStock <= item.minStockAlert) {
        totalDeficit++;
      }
      if (widget.adapter.isInReceipt(item)) {
        totalInReceipt++;
      }
    }

    // 2. Фильтрация позиций
    final filteredItems = widget.availableIngredients.where((item) {
      if (_searchQuery.isNotEmpty) {
        final matchesName = item.name.toLowerCase().contains(_searchQuery);
        final matchesSku = item.sku?.toLowerCase().contains(_searchQuery) ?? false;
        final matchesBarcode = item.barcode?.toLowerCase().contains(_searchQuery) ?? false;
        final matchesCat = item.categoryName?.toLowerCase().contains(_searchQuery) ?? false;
        if (!matchesName && !matchesSku && !matchesBarcode && !matchesCat) {
          return false;
        }
      }

      switch (_activeFilter) {
        case ReceiveCategoryFilter.all:
          return true;
        case ReceiveCategoryFilter.onlyDeficit:
          return item.isLowStock || item.currentStock <= item.minStockAlert;
        case ReceiveCategoryFilter.inReceipt:
          return widget.adapter.isInReceipt(item);
      }
    }).toList();

    // 3. Группировка позиций по категориям
    final Map<String, List<Ingredient>> grouped = {};
    for (final item in filteredItems) {
      final cat = (item.categoryName != null && item.categoryName!.trim().isNotEmpty)
          ? item.categoryName!.trim()
          : 'Без категории';
      grouped.putIfAbsent(cat, () => []).add(item);
    }

    // Сортировка категорий (Без категории — в конце)
    final sortedCategories = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'Без категории') return 1;
        if (b == 'Без категории') return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    // 4. Построение плоского виртуализированного списка (Flat List Virtualization)
    final List<dynamic> flatList = [];
    for (final catName in sortedCategories) {
      final catItems = grouped[catName]!;
      final isExpanded = _searchQuery.isNotEmpty
          ? (_expansionMap[catName] ?? true)
          : (_expansionMap[catName] ??
              (_activeFilter != ReceiveCategoryFilter.all || _isAllExpanded));

      // 4.1 Заголовок категории (аккордеон)
      flatList.add({
        'type': 'header',
        'categoryName': catName,
        'items': catItems,
        'isExpanded': isExpanded,
      });

      // 4.2 Если раскрыто и есть позиции — добавляем шапку таблицы и виртуализированные строки
      if (isExpanded && catItems.isNotEmpty) {
        final bool showRetail = widget.isRetail || catItems.any((i) => i.isRetail);
        flatList.add({
          'type': 'table_header',
          'showRetail': showRetail,
        });

        for (int i = 0; i < catItems.length; i++) {
          flatList.add({
            'type': 'item',
            'item': catItems[i],
            'showRetail': showRetail,
            'isLast': i == catItems.length - 1,
          });
        }
      }
    }

    return Expanded(
      child: Column(
        children: [
          // Тулбар поиска и фильтрации
          ReceiveCategoryToolbar(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            activeFilter: _activeFilter,
            onFilterChanged: _onFilterChanged,
            deficitCount: totalDeficit,
            inReceiptCount: totalInReceipt,
            isAllExpanded: _isAllExpanded,
            onToggleExpandAll: () => _toggleExpandAll(sortedCategories),
          ),

          // Единый виртуализированный список (строит только видимые строки на экране)
          Expanded(
            child: sortedCategories.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: flatList.length,
                    itemBuilder: (context, index) {
                      final entry = flatList[index];
                      if (entry['type'] == 'header') {
                        final catName = entry['categoryName'] as String;
                        final isExpanded = entry['isExpanded'] as bool;
                        return ReceiveCategoryAccordion(
                          key: ValueKey('header-$catName'),
                          categoryName: catName,
                          items: entry['items'] as List<Ingredient>,
                          isRetail: widget.isRetail,
                          currency: widget.currency,
                          isExpanded: isExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _expansionMap[catName] = expanded;
                            });
                          },
                          adapter: widget.adapter,
                        );
                      } else if (entry['type'] == 'table_header') {
                        return ReceiveCategoryTableHeader(
                          showRetail: entry['showRetail'] as bool,
                          currency: widget.currency,
                        );
                      } else {
                        final item = entry['item'] as Ingredient;
                        final showRetail = entry['showRetail'] as bool;
                        final isLast = entry['isLast'] as bool;
                        return ReceiveCategoryItemRow(
                          key: ValueKey('item-${item.id}'),
                          item: item,
                          showRetailColumn: showRetail,
                          currency: widget.currency,
                          adapter: widget.adapter,
                          isLast: isLast,
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsRegular.magnifyingGlass,
            size: 36,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
          const SizedBox(height: 12),
          Text(
            'Товары не найдены',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Попробуйте изменить поисковый запрос или сбросить фильтры',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
        ],
      ),
    );
  }
}
