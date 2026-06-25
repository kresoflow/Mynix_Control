import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:retail_os_frontend/features/inventory/view/receive_retail_screen.dart';
import 'package:retail_os_frontend/features/inventory/view/widgets/retail_product_modal.dart';
import 'package:retail_os_frontend/features/inventory/view/inventory_matrix_screen.dart';

import 'package:retail_os_frontend/features/inventory/view/widgets/warehouse/add_category_dialog.dart';
import 'package:retail_os_frontend/features/inventory/view/widgets/warehouse/add_ingredient_dialog.dart';
import 'package:retail_os_frontend/features/inventory/view/widgets/warehouse/stock_tab.dart';
import 'package:retail_os_frontend/features/inventory/view/widgets/warehouse/write_off_tab.dart';

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
                    Tab(icon: Icon(PhosphorIconsRegular.gridFour), text: 'Матрица (Excel)'),
                    Tab(icon: Icon(PhosphorIconsRegular.package), text: 'Остатки'),
                    Tab(icon: Icon(PhosphorIconsRegular.truck), text: 'Приход'),
                    Tab(
                      icon: Icon(PhosphorIconsRegular.shoppingCart),
                      text: 'Списания',
                    ),
                    Tab(icon: Icon(PhosphorIconsRegular.clipboardText), text: 'Инвентаризация'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(PhosphorIconsRegular.plusSquare, size: 18),
                label: const Text('Категория'),
                onPressed: () => AddCategoryDialog.show(context),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(PhosphorIconsRegular.cookingPot, size: 18),
                label: const Text('Сырье'),
                onPressed: () => AddIngredientDialog.show(context),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(PhosphorIconsRegular.storefront, size: 18),
                label: const Text('Витрина'),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const RetailProductModal(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              InventoryMatrixScreen(),
              StockTab(filter: 'all'),
              ReceiveRetailScreen(),
              WriteOffTab(),
              Center(
                child: Text(
                  'Инвентаризация (В разработке)',
                  style: TextStyle(fontSize: 24, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
