// ==============================================================================
// МОДУЛЬ: Склад / Секция прихода товаров по категориям склада
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/category_mode/
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'receive_category_accordion.dart';
import 'receive_category_sync_adapter.dart';
import 'receive_category_toolbar.dart';

/// Секция прихода номенклатуры в виде структурированного каталога категорий склада.
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
      if (widget.adapter.isInReceipt(item.id)) {
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
          return widget.adapter.isInReceipt(item.id);
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

          // Список аккордеонов категорий
          Expanded(
            child: sortedCategories.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: sortedCategories.length,
                    itemBuilder: (context, index) {
                      final catName = sortedCategories[index];
                      final catItems = grouped[catName]!;
                      final isExpanded = _searchQuery.isNotEmpty
                          ? (_expansionMap[catName] ?? true)
                          : (_expansionMap[catName] ??
                              (_activeFilter != ReceiveCategoryFilter.all || _isAllExpanded));

                      return ReceiveCategoryAccordion(
                        key: ValueKey(catName),
                        categoryName: catName,
                        items: catItems,
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
