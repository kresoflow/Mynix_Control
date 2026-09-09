import 'package:flutter/material.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_browser_tab.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add_modal.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
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
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(icon: Icon(PhosphorIconsRegular.squaresFour), text: 'Категории'),
                    Tab(icon: Icon(PhosphorIconsRegular.hamburger), text: 'Блюда'),
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
                addMenuBuilder: (context, currentCategoryId) => PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'dish') {
                      showAddCategoryDialog(context, currentCategoryId: currentCategoryId, type: 'dish');
                    } else if (val == 'retail') {
                      showAddCategoryDialog(context, currentCategoryId: currentCategoryId, type: 'retail');
                    } else if (val == 'bulk_add') {
                      showDialog(
                        context: context,
                        builder: (ctx) => BulkAddModal(initialTabIndex: 3, initialParentId: currentCategoryId),
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'dish', child: ListTile(leading: Icon(PhosphorIconsRegular.hamburger), title: Text('Папка для Блюд'))),
                    const PopupMenuItem(value: 'retail', child: ListTile(leading: Icon(PhosphorIconsRegular.storefront), title: Text('Папка для Витрины'))),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'bulk_add', child: ListTile(leading: Icon(PhosphorIconsRegular.table), title: Text('Массовое добавление'))),
                  ],
                  child: IgnorePointer(
                    child: AppPrimaryButton(
                      label: 'Добавить',
                      icon: PhosphorIconsRegular.plus,
                      height: 36,
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
              CatalogBrowserTab(
                categoryType: 'dish',
                rootTitle: 'Все блюда',
                itemFilter: (item) => !item.isRetail,
                emptyMessage: 'В меню пока пусто. Добавьте блюда или категории.',
                addMenuBuilder: (context, currentCategoryId) => PopupMenuButton<String>(
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
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'dish', child: ListTile(leading: Icon(PhosphorIconsRegular.hamburger), title: Text('Блюдо'))),
                    const PopupMenuItem(value: 'category', child: ListTile(leading: Icon(PhosphorIconsRegular.folderPlus), title: Text('Категория'))),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'bulk_add', child: ListTile(leading: Icon(PhosphorIconsRegular.table), title: Text('Массовое добавление'))),
                  ],
                  child: IgnorePointer(
                    child: AppPrimaryButton(
                      label: 'Добавить',
                      icon: PhosphorIconsRegular.plus,
                      height: 36,
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
              CatalogBrowserTab(
                categoryType: 'retail',
                rootTitle: 'Вся витрина',
                itemFilter: (item) => item.isRetail,
                emptyMessage: 'На витрине пока пусто. Добавьте товары или категории.',
                addMenuBuilder: (context, currentCategoryId) => PopupMenuButton<String>(
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
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'retail', child: ListTile(leading: Icon(PhosphorIconsRegular.storefront), title: Text('Товар витрины'))),
                    const PopupMenuItem(value: 'category', child: ListTile(leading: Icon(PhosphorIconsRegular.folderPlus), title: Text('Категория'))),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'bulk_add', child: ListTile(leading: Icon(PhosphorIconsRegular.table), title: Text('Массовое добавление'))),
                  ],
                  child: IgnorePointer(
                    child: AppPrimaryButton(
                      label: 'Добавить',
                      icon: PhosphorIconsRegular.plus,
                      height: 36,
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
