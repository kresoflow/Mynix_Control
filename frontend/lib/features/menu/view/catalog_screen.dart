import 'package:flutter/material.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_browser_tab.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
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
                    showAddCategoryDialog(context, currentCategoryId: currentCategoryId, type: val);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'dish', child: ListTile(leading: Icon(PhosphorIconsRegular.hamburger), title: Text('Папка для Блюд'))),
                    const PopupMenuItem(value: 'retail', child: ListTile(leading: Icon(PhosphorIconsRegular.storefront), title: Text('Папка для Витрины'))),
                  ],
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(PhosphorIconsRegular.plus, color: Colors.white),
                    label: const Text('Добавить', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      disabledBackgroundColor: Theme.of(context).colorScheme.primary,
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
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'category', child: ListTile(leading: Icon(PhosphorIconsRegular.folderPlus), title: Text('Категория'))),
                    const PopupMenuItem(value: 'dish', child: ListTile(leading: Icon(PhosphorIconsRegular.hamburger), title: Text('Блюдо'))),
                  ],
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(PhosphorIconsRegular.plus, color: Colors.white),
                    label: const Text('Добавить', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      disabledBackgroundColor: Theme.of(context).colorScheme.primary,
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
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'category', child: ListTile(leading: Icon(PhosphorIconsRegular.folderPlus), title: Text('Категория'))),
                    const PopupMenuItem(value: 'retail', child: ListTile(leading: Icon(PhosphorIconsRegular.storefront), title: Text('Товар витрины'))),
                  ],
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(PhosphorIconsRegular.plus, color: Colors.white),
                    label: const Text('Добавить', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      disabledBackgroundColor: Theme.of(context).colorScheme.primary,
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
