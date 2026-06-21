import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:retail_os_frontend/features/inventory/view/widgets/warehouse/receive_stock_dialog.dart';

class StockTab extends StatefulWidget {
  final String filter;
  const StockTab({super.key, required this.filter});

  @override
  State<StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<StockTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late String _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('Все')),
              ButtonSegment(value: 'raw', label: Text('Сырье для кухни')),
              ButtonSegment(value: 'retail', label: Text('Витрина')),
            ],
            selected: {_filter},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _filter = newSelection.first;
              });
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<IngredientBloc, IngredientState>(
            builder: (context, state) {
              if (state is IngredientLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is IngredientLoaded) {
                // Apply filter based on widget.filter
                final filtered = state.ingredients.where((item) {
                  final isRetail =
                      item.attributes != null &&
                      item.attributes!['is_retail'] == true;
                  if (_filter == 'retail') return isRetail;
                  if (_filter == 'raw') return !isRetail;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Нет товаров в этой категории.'),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isLowStock = item.isLowStock;
                          final isRetail =
                              item.attributes != null &&
                              item.attributes!['is_retail'] == true;

                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                isRetail ? Icons.storefront : Icons.kitchen,
                                color: isLowStock ? Colors.red : Colors.grey,
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(fontSize: 16),
                              ),
                              subtitle: Text(
                                'Остаток: ${item.currentStock} ${item.unit} | Мин: ${item.minStockAlert} ${item.unit}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${item.costPerUnit.toStringAsFixed(2)} с / ${item.unit}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        ReceiveStockDialog.show(context, item),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Приход'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }
              return const Center(child: Text('Ошибка загрузки склада'));
            },
          ),
        ),
      ],
    );
  }
}
