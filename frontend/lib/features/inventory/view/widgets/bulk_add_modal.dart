import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'bulk_add/dish_row.dart';
import 'bulk_add/ingredient_row.dart';
import 'bulk_add/retail_row.dart';
import 'bulk_add/bulk_add_category_selector.dart';
import 'bulk_add/bulk_add_save_helper.dart';

class BulkAddModal extends StatefulWidget {
  final int initialTabIndex;
  const BulkAddModal({super.key, this.initialTabIndex = 0});

  @override
  State<BulkAddModal> createState() => _BulkAddModalState();
}

class _BulkAddModalState extends State<BulkAddModal> {
  int _tabIndex = 0; // 0 = Блюда, 1 = Товары витрины, 2 = Сырье

  int? _selectedParentId;
  int? _selectedChildId;

  final List<DishRowData> _dishRows = [];
  final List<RetailRowData> _retailRows = [];
  final List<IngredientRowData> _ingredientRows = [];

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex;
    _addRow();
  }

  void _addRow() {
    setState(() {
      if (_tabIndex == 0) {
        _dishRows.add(DishRowData());
      } else if (_tabIndex == 1) {
        _retailRows.add(RetailRowData());
      } else {
        _ingredientRows.add(IngredientRowData());
      }
    });
    _focusRow(
      _tabIndex == 0
          ? _dishRows.last.firstFocusNode
          : (_tabIndex == 1
                ? _retailRows.last.firstFocusNode
                : _ingredientRows.last.firstFocusNode),
    );
  }

  void _focusRow(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (node.canRequestFocus) {
        node.requestFocus();
      }
    });
  }

  void _duplicateRow(int index) {
    setState(() {
      if (_tabIndex == 0) {
        _dishRows.insert(index + 1, _dishRows[index].clone());
      } else if (_tabIndex == 1) {
        _retailRows.insert(index + 1, _retailRows[index].clone());
      } else {
        _ingredientRows.insert(index + 1, _ingredientRows[index].clone());
      }
    });
    _focusRow(
      _tabIndex == 0
          ? _dishRows[index + 1].firstFocusNode
          : (_tabIndex == 1
                ? _retailRows[index + 1].firstFocusNode
                : _ingredientRows[index + 1].firstFocusNode),
    );
  }

  void _removeRow(int index) {
    setState(() {
      if (_tabIndex == 0) {
        _dishRows.removeAt(index);
      } else if (_tabIndex == 1) {
        _retailRows.removeAt(index);
      } else {
        _ingredientRows.removeAt(index);
      }
    });
  }

  void _saveAll() {
    performBulkSave(
      context: context,
      tabIndex: _tabIndex,
      targetCategoryId: _selectedChildId ?? _selectedParentId,
      dishRows: _dishRows,
      ingredientRows: _ingredientRows,
      retailRows: _retailRows,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _saveAll,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _saveAll,
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text(
                      'Массовое добавление',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.x),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Блюда')),
                        ButtonSegment(value: 1, label: Text('Товары витрины')),
                        ButtonSegment(
                          value: 2,
                          label: Text('Сырье / Ингредиенты'),
                        ),
                      ],
                      selected: {_tabIndex},
                      onSelectionChanged: (val) {
                        setState(() {
                          _tabIndex = val.first;
                          if ((_tabIndex == 0 && _dishRows.isEmpty) ||
                              (_tabIndex == 1 && _retailRows.isEmpty) ||
                              (_tabIndex == 2 && _ingredientRows.isEmpty)) {
                            _addRow();
                          }
                        });
                      },
                    ),
                    ElevatedButton.icon(
                      onPressed: _addRow,
                      icon: const Icon(PhosphorIconsRegular.plus),
                      label: const Text('Добавить строку'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                BulkAddCategorySelector(
                  tabIndex: _tabIndex,
                  selectedParentId: _selectedParentId,
                  selectedChildId: _selectedChildId,
                  onParentChanged: (val) => setState(() {
                    _selectedParentId = val;
                  }),
                  onChildChanged: (val) =>
                      setState(() => _selectedChildId = val),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: _tabIndex == 0
                        ? _dishRows.length
                        : (_tabIndex == 1
                              ? _retailRows.length
                              : _ingredientRows.length),
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 12.0,
                              right: 8.0,
                            ),
                            child: Text(
                              '${index + 1}.',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _tabIndex == 0
                                ? DishRowWidget(
                                    row: _dishRows[index],
                                    onAddRow: _addRow,
                                  )
                                : (_tabIndex == 1
                                      ? RetailRowWidget(
                                          row: _retailRows[index],
                                          onAddRow: _addRow,
                                        )
                                      : IngredientRowWidget(
                                          row: _ingredientRows[index],
                                          onAddRow: _addRow,
                                        )),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  PhosphorIconsRegular.copy,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _duplicateRow(index),
                                tooltip: 'Дублировать',
                              ),
                              IconButton(
                                icon: const Icon(
                                  PhosphorIconsRegular.trash,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeRow(index),
                                tooltip: 'Удалить',
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _saveAll,
                    child: const Text(
                      'Сохранить всё (Ctrl+S)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var r in _dishRows) {
      r.firstFocusNode.dispose();
    }
    for (var r in _retailRows) {
      r.firstFocusNode.dispose();
    }
    for (var r in _ingredientRows) {
      r.firstFocusNode.dispose();
    }
    super.dispose();
  }
}
