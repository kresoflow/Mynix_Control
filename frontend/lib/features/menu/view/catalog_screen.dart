import 'package:flutter/material.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/catalog_browser_tab.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add_modal.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).cardColor,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(icon: Icon(PhosphorIconsRegular.folder), text: 'Категории'),
                    Tab(icon: Icon(PhosphorIconsRegular.cookingPot), text: 'Блюда'),
                    Tab(icon: Icon(PhosphorIconsRegular.storefront), text: 'Витрина'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              CatalogBrowserTab(
                categoryType: 'all',
                rootTitle: 'Все категории',
                itemFilter: (item) => true,
                emptyMessage: 'Категорий пока нет.',
                addMenuBuilder: (context, currentCategoryId) => AppMenuButton(
                  label: 'Добавить',
                  icon: PhosphorIconsRegular.plus,
                  size: AppButtonSize.md,
                  items: const [
                    AppMenuItem(id: 'category_dish', label: 'Категория блюд', icon: PhosphorIconsRegular.folderPlus),
                    AppMenuItem(id: 'category_retail', label: 'Категория витрины', icon: PhosphorIconsRegular.storefront),
                    AppMenuDivider(),
                    AppMenuItem(id: 'dish', label: 'Блюдо', icon: PhosphorIconsRegular.cookingPot),
                    AppMenuItem(id: 'retail', label: 'Товар', icon: PhosphorIconsRegular.barcode),
                    AppMenuDivider(),
                    AppMenuItem(id: 'bulk_add', label: 'Массовый ввод', icon: PhosphorIconsRegular.table),
                  ],
                  onSelected: (val) {
                    if (val == 'category_dish') {
                      showAddCategoryDialog(context, currentCategoryId: currentCategoryId, type: 'dish');
                    } else if (val == 'category_retail') {
                      showAddCategoryDialog(context, currentCategoryId: currentCategoryId, type: 'retail');
                    } else if (val == 'dish') {
                      showAddMenuItemDialog(context, currentCategoryId: currentCategoryId);
                    } else if (val == 'retail') {
                      showAddRetailProductDialog(context, currentCategoryId: currentCategoryId);
                    } else if (val == 'bulk_add') {
                      showDialog(
                        context: context,
                        builder: (ctx) => BulkAddModal(initialTabIndex: 3, initialParentId: currentCategoryId),
                      );
                    }
                  },
                ),
              ),
              CatalogBrowserTab(
                categoryType: 'dish',
                rootTitle: 'Все блюда',
                itemFilter: (item) => !item.isRetail,
                emptyMessage: 'В меню пока пусто. Добавьте блюда или категории.',
                addMenuBuilder: (context, currentCategoryId) => AppMenuButton(
                  label: 'Добавить',
                  icon: PhosphorIconsRegular.plus,
                  size: AppButtonSize.md,
                  items: const [
                    AppMenuItem(id: 'dish', label: 'Блюдо', icon: PhosphorIconsRegular.cookingPot),
                    AppMenuItem(id: 'category', label: 'Категория блюд', icon: PhosphorIconsRegular.folderPlus),
                    AppMenuDivider(),
                    AppMenuItem(id: 'bulk_add', label: 'Массовый ввод', icon: PhosphorIconsRegular.table),
                  ],
                  onSelected: (val) {
                    if (val == 'category') {
                      showAddCategoryDialog(context, currentCategoryId: currentCategoryId, type: 'dish');
                    } else if (val == 'dish') {
                      showAddMenuItemDialog(context, currentCategoryId: currentCategoryId);
                    } else if (val == 'bulk_add') {
                      showDialog(
                        context: context,
                        builder: (ctx) => BulkAddModal(initialTabIndex: 0, initialParentId: currentCategoryId),
                      );
                    }
                  },
                ),
              ),
              CatalogBrowserTab(
                categoryType: 'retail',
                rootTitle: 'Вся витрина',
                itemFilter: (item) => item.isRetail,
                emptyMessage: 'На витрине пока пусто. Добавьте товары или категории.',
                addMenuBuilder: (context, currentCategoryId) => AppMenuButton(
                  label: 'Добавить',
                  icon: PhosphorIconsRegular.plus,
                  size: AppButtonSize.md,
                  items: const [
                    AppMenuItem(id: 'retail', label: 'Товар', icon: PhosphorIconsRegular.barcode),
                    AppMenuItem(id: 'category', label: 'Категория витрины', icon: PhosphorIconsRegular.storefront),
                    AppMenuDivider(),
                    AppMenuItem(id: 'bulk_add', label: 'Массовый ввод', icon: PhosphorIconsRegular.table),
                  ],
                  onSelected: (val) {
                    if (val == 'category') {
                      showAddCategoryDialog(context, currentCategoryId: currentCategoryId, type: 'retail');
                    } else if (val == 'retail') {
                      showAddRetailProductDialog(context, currentCategoryId: currentCategoryId);
                    } else if (val == 'bulk_add') {
                      showDialog(
                        context: context,
                        builder: (ctx) => BulkAddModal(initialTabIndex: 1, initialParentId: currentCategoryId),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
