import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/stock_tab.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/documents_journal_tab.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/suppliers_tab.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/ingredient_tab.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/recipe_tab.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
                    Tab(icon: Icon(PhosphorIconsRegular.package), text: 'Остатки'),
                    Tab(icon: Icon(PhosphorIconsRegular.cookingPot), text: 'Сырье'),
                    Tab(icon: Icon(PhosphorIconsRegular.receipt), text: 'Техкарты'),
                    Tab(icon: Icon(PhosphorIconsRegular.bookOpenText), text: 'Журнал Документов'),
                    Tab(icon: Icon(PhosphorIconsRegular.truck), text: 'Поставщики'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              StockTab(filter: 'all'),
              IngredientTab(),
              RecipeTab(),
              DocumentsJournalTab(),
              SuppliersTab(),
            ],
          ),
        ),
      ],
    );
  }
}
