// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/pos/models/menu_category.dart';

// ==============================================================================
// 2. МОДЕЛЬ РЕЗУЛЬТАТА ИЕРАРХИЧЕСКОЙ СБОРКИ
// ==============================================================================
/// [ИНВАРИАНТ] DTO агрегированных данных и плоского списка элементов остатков склада.
class StockHierarchyResult {
  final List<dynamic> flatList;
  final Map<String, double> categoryCapitals;
  final double totalCapital;
  final double potentialRevenue;
  final int lowStockCount;
  final List<Ingredient> lowStockItems;

  const StockHierarchyResult({
    required this.flatList,
    required this.categoryCapitals,
    required this.totalCapital,
    required this.potentialRevenue,
    required this.lowStockCount,
    required this.lowStockItems,
  });
}

// ==============================================================================
// 3. ДОМЕННЫЙ ПОСТРОИТЕЛЬ ИЕРАРХИИ СКЛАДА
// ==============================================================================
/// [ИНВАРИАНТ] Сервис расчета многоуровневой иерархии категорий и метрик капитала.
abstract class StockHierarchyBuilder {
  /// Определяет путь категории (Корневая папка и Подпапка) для номенклатурной позиции.
  static (String rootName, String subName) getCategoryHierarchy(
    Ingredient item,
    List<MenuCategory> allCategories,
  ) {
    if (item.categoryId == null) {
      return (item.categoryName ?? 'Без категории', '');
    }

    final currentCat =
        allCategories.where((c) => c.id == item.categoryId).firstOrNull;
    if (currentCat == null) {
      return (item.categoryName ?? 'Без категории', '');
    }

    if (currentCat.parentId == null) {
      return (currentCat.name, '');
    }

    var root =
        allCategories.where((c) => c.id == currentCat.parentId).firstOrNull;
    final visited = <int>{currentCat.id, if (root != null) root.id};

    while (root?.parentId != null) {
      if (visited.contains(root!.parentId)) break;
      final parent =
          allCategories.where((c) => c.id == root!.parentId).firstOrNull;
      if (parent == null) break;
      visited.add(parent.id);
      root = parent;
    }

    return (root?.name ?? currentCat.name, currentCat.name);
  }

  /// Собирает плоский список виртуализации и агрегирует финансовые метрики склада.
  static StockHierarchyResult build({
    required List<Ingredient> items,
    required List<MenuCategory> allCategories,
    required String searchQuery,
    required Map<String, bool> expandedCategories,
    required Map<String, bool> expandedSubcategories,
    required bool isExpandedAll,
  }) {
    double totalCapital = 0;
    double potentialRevenue = 0;
    int lowStockCount = 0;
    final List<Ingredient> lowStockItems = [];

    for (final item in items) {
      if (item.currentStock > 0) {
        totalCapital += item.currentStock * item.costPerUnit;
        potentialRevenue +=
            item.currentStock * (item.price ?? item.costPerUnit);
      }
      if (item.isLowStock || item.currentStock <= 0) {
        lowStockCount++;
        lowStockItems.add(item);
      }
    }

    // Двухуровневая группировка: Корневая категория -> Подкатегории -> Позиции
    final Map<String, Map<String, List<Ingredient>>> hierarchy = {};
    final Map<String, List<Ingredient>> allRootItems = {};
    final Map<String, double> categoryCapitals = {};

    for (final item in items) {
      final (rootName, subName) = getCategoryHierarchy(item, allCategories);

      hierarchy.putIfAbsent(rootName, () => {});
      hierarchy[rootName]!.putIfAbsent(subName, () => []).add(item);

      allRootItems.putIfAbsent(rootName, () => []).add(item);

      if (!expandedCategories.containsKey(rootName)) {
        expandedCategories[rootName] = isExpandedAll;
      }

      final subKey = '$rootName::$subName';
      if (!expandedSubcategories.containsKey(subKey)) {
        expandedSubcategories[subKey] = isExpandedAll;
      }

      if (item.currentStock > 0) {
        categoryCapitals[rootName] =
            (categoryCapitals[rootName] ?? 0) + (item.currentStock * item.costPerUnit);
      }
    }

    final sortedRootCategories = hierarchy.keys.toList()
      ..sort((a, b) {
        if (a == 'Без категории') return 1;
        if (b == 'Без категории') return -1;
        return a.compareTo(b);
      });

    // Построение плоского списка для виртуализированного рендеринга (Flat Virtualization)
    final List<dynamic> flatList = [];
    for (final rootCategory in sortedRootCategories) {
      final catItems = allRootItems[rootCategory]!;
      final subMap = hierarchy[rootCategory]!;
      final isRootExpanded =
          searchQuery.isNotEmpty || (expandedCategories[rootCategory] ?? false);

      flatList.add({
        'type': 'header',
        'categoryName': rootCategory,
        'items': catItems,
        'isExpanded': isRootExpanded,
      });

      if (isRootExpanded) {
        final hasRealSubcategories = subMap.keys.any((k) => k.isNotEmpty);

        if (hasRealSubcategories) {
          final sortedSubcategories = subMap.keys.toList()
            ..sort((a, b) {
              if (a.isEmpty) return -1;
              if (b.isEmpty) return 1;
              return a.compareTo(b);
            });

          for (final subName in sortedSubcategories) {
            final subItems = subMap[subName]!;
            final subKey = '$rootCategory::$subName';
            final isSubExpanded = searchQuery.isNotEmpty ||
                (expandedSubcategories[subKey] ?? false);

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
          for (int i = 0; i < catItems.length; i++) {
            flatList.add({
              'type': 'item',
              'item': catItems[i],
              'isLast': i == catItems.length - 1,
            });
          }
        }
      }
    }

    return StockHierarchyResult(
      flatList: flatList,
      categoryCapitals: categoryCapitals,
      totalCapital: totalCapital,
      potentialRevenue: potentialRevenue,
      lowStockCount: lowStockCount,
      lowStockItems: lowStockItems,
    );
  }
}
