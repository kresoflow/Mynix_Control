import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:retail_os_frontend/features/pos/bloc/menu_bloc.dart';
import 'widgets/inventory_matrix_data_builder.dart';

class InventoryMatrixScreen extends StatefulWidget {
  const InventoryMatrixScreen({super.key});

  @override
  State<InventoryMatrixScreen> createState() => _InventoryMatrixScreenState();
}

class _InventoryMatrixScreenState extends State<InventoryMatrixScreen> {
  late PlutoGridStateManager stateManager;
  final List<PlutoColumn> columns = [];
  final List<PlutoRow> rows = [];

  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _initColumns();
  }

  void _initColumns() {
    columns.addAll(InventoryMatrixDataBuilder.buildColumns());
  }

  void _buildRows(
    CategoryState catState,
    IngredientState ingState,
    MenuState menuState,
  ) {
    rows.clear();
    rows.addAll(
      InventoryMatrixDataBuilder.buildRows(catState, ingState, menuState),
    );
  }

  void _saveChanges() {
    // Logic to dispatch events for dirty rows
    // Reset dirty state
    setState(() {
      _isDirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Изменения сохранены (В разработке)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, catState) {
        return BlocBuilder<IngredientBloc, IngredientState>(
          builder: (context, ingState) {
            return BlocBuilder<MenuBloc, MenuState>(
              builder: (context, menuState) {
                if (catState is CategoryLoading ||
                    ingState is IngredientLoading ||
                    menuState is MenuLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (rows.isEmpty &&
                    catState is CategoryLoaded &&
                    ingState is IngredientLoaded &&
                    menuState is MenuLoaded) {
                  _buildRows(catState, ingState, menuState);
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Матрица Товаров (Excel)',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(PhosphorIconsRegular.plus),
                                label: const Text('Добавить строку'),
                                onPressed: () {
                                  stateManager.insertRows(0, [
                                    PlutoRow(
                                      cells: {
                                        'name': PlutoCell(value: 'Новый товар'),
                                        'type': PlutoCell(value: 'Сырье'),
                                        'unit': PlutoCell(value: 'шт'),
                                        'stock': PlutoCell(value: 0),
                                        'cost': PlutoCell(value: 0),
                                        'retail_price': PlutoCell(value: 0),
                                        'id': PlutoCell(
                                          value:
                                              'new_${DateTime.now().millisecondsSinceEpoch}',
                                        ),
                                      },
                                    ),
                                  ]);
                                  setState(() => _isDirty = true);
                                },
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                icon: const Icon(PhosphorIconsRegular.floppyDisk),
                                label: const Text('Сохранить изменения'),
                                onPressed: _isDirty ? _saveChanges : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isDirty
                                      ? Colors.green
                                      : Colors.grey,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: PlutoGrid(
                          columns: columns,
                          rows: rows,
                          onLoaded: (PlutoGridOnLoadedEvent event) {
                            stateManager = event.stateManager;
                            stateManager.setShowColumnFilter(true);
                            stateManager.setRowGroup(
                              PlutoRowGroupTreeDelegate(
                                resolveColumnDepth: (column) =>
                                    column.field == 'name' ? 0 : 1,
                                showText: (context) => true,
                                showCount: false,
                                showFirstExpandableIcon: true,
                              ),
                            );
                          },
                          onChanged: (PlutoGridOnChangedEvent event) {
                            if (!_isDirty) {
                              setState(() {
                                _isDirty = true;
                              });
                            }
                          },
                          configuration: PlutoGridConfiguration(
                            style: PlutoGridStyleConfig(
                              enableGridBorderShadow: true,
                              gridBorderColor: Colors.transparent,
                              borderColor: Colors.grey.withValues(alpha: 0.2),
                              rowHeight: 48,
                              activatedBorderColor: Theme.of(
                                context,
                              ).primaryColor,
                            ),
                          ),
                          rowColorCallback: (rowColorContext) {
                            if (rowColorContext.row.cells['type']?.value ==
                                'Категория') {
                              return Colors.grey.withValues(alpha: 0.1);
                            }
                            return Colors.transparent;
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
