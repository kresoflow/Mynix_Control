import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_event.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class RetailProductModal extends StatefulWidget {
  final int? preselectedCategoryId;

  const RetailProductModal({super.key, this.preselectedCategoryId});

  @override
  State<RetailProductModal> createState() => _RetailProductModalState();
}

class _RetailProductModalState extends State<RetailProductModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _initialStockController;
  late TextEditingController _barcodeController;

  int? _selectedCategoryId;
  String _selectedUnit = 'pcs';
  bool _hasVariations = false;
  final TextEditingController _flavorController = TextEditingController();
  final List<Map<String, dynamic>> _variations = [];

  final Map<String, String> _units = {
    'pcs': 'шт',
    'kg': 'кг',
    'g': 'г',
    'l': 'л',
    'ml': 'мл',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _purchasePriceController = TextEditingController();
    _sellingPriceController = TextEditingController();
    _initialStockController = TextEditingController(text: '0');
    _barcodeController = TextEditingController();
    _selectedCategoryId = widget.preselectedCategoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _initialStockController.dispose();
    _barcodeController.dispose();
    _flavorController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
      final name = _nameController.text.trim();

      if (_hasVariations) {
        if (_variations.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Добавьте хотя бы одну опцию')),
          );
          return;
        }
        final flavor = _flavorController.text.trim();
        
        context.read<MenuBloc>().add(
          CreateRetailProductGroup(
            name: name,
            categoryId: _selectedCategoryId!,
            flavor: flavor,
            variations: _variations,
          ),
        );
      } else {
        final purchasePrice =
            double.tryParse(_purchasePriceController.text) ?? 0.0;
        final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0.0;
        final initialStock = double.tryParse(_initialStockController.text) ?? 0.0;
        final barcode = _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim();

        context.read<MenuBloc>().add(
          CreateRetailProduct(
            name: name,
            categoryId: _selectedCategoryId!,
            unit: _selectedUnit,
            purchasePrice: purchasePrice,
            sellingPrice: sellingPrice,
            initialStock: initialStock,
            barcode: barcode,
          ),
        );
      }

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните все поля корректно'),
        ),
      );
    }
  }

  void _showCreateCategoryDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новая категория'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Название',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                context.read<CategoryBloc>().add(
                  CreateCategory(name: nameCtrl.text.trim()),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Категория добавляется...')),
                );
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Добавить товар витрины',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Обязательное поле' : null,
              ),
              const SizedBox(height: 16),
              BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  if (state is CategoryLoaded) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Категория',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _selectedCategoryId,
                            items: state.categories.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCategoryId = val;
                              });
                            },
                            validator: (v) =>
                                v == null ? 'Выберите категорию' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: IconButton(
                            icon: Icon(
                              PhosphorIconsRegular.plusSquare,
                              size: 40,
                              color: AppColors.brandPrimary,
                            ),
                            onPressed: _showCreateCategoryDialog,
                            tooltip: 'Новая категория',
                          ),
                        ),
                      ],
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Несколько опций/вкусов? (Опции товара)'),
                value: _hasVariations,
                onChanged: (v) {
                  setState(() {
                    _hasVariations = v;
                    if (v && _variations.isEmpty) {
                      _variations.add({
                        'name': '',
                        'price': 0,
                        'purchasePrice': 0,
                        'stock': 0,
                        'barcode': '',
                        'unit': 'pcs'
                      });
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              if (!_hasVariations) ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Ед. изм.',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedUnit,
                      items: _units.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedUnit = val!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _initialStockController,
                      decoration: const InputDecoration(
                        labelText: 'Нач. остаток',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Заполните' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Цена закупки',
                        border: OutlineInputBorder(),
                        prefixText: 'TJS ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Заполните' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Цена продажи (розница)',
                        border: OutlineInputBorder(),
                        prefixText: 'TJS ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Заполните' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Штрихкод',
                  hintText: 'Отсканируйте или введите вручную',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(PhosphorIconsRegular.barcode, color: AppColors.brandPrimary),
                ),
                keyboardType: TextInputType.text,
              ),
              ] else ...[
                TextFormField(
                  controller: _flavorController,
                  decoration: const InputDecoration(
                    labelText: 'Вкус / Описание группы (необязательно)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Опции (Объемы / Вариации)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: _variations.length,
                    itemBuilder: (context, i) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: _variations[i]['name'],
                                      decoration: const InputDecoration(labelText: 'Опция (напр. 0.5л)', isDense: true),
                                      onChanged: (v) => _variations[i]['name'] = v,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(isDense: true),
                                      value: _variations[i]['unit'],
                                      items: _units.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                                      onChanged: (val) => setState(() => _variations[i]['unit'] = val),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(PhosphorIconsRegular.trash, color: Colors.red),
                                    onPressed: () => setState(() => _variations.removeAt(i)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _variations[i]['purchasePrice'].toString(),
                                      decoration: const InputDecoration(labelText: 'Закупка', prefixText: 'TJS ', isDense: true),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => _variations[i]['purchasePrice'] = double.tryParse(v) ?? 0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _variations[i]['price'].toString(),
                                      decoration: const InputDecoration(labelText: 'Продажа', prefixText: 'TJS ', isDense: true),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => _variations[i]['price'] = double.tryParse(v) ?? 0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _variations[i]['stock'].toString(),
                                      decoration: const InputDecoration(labelText: 'Нач. остаток', isDense: true),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => _variations[i]['stock'] = double.tryParse(v) ?? 0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: _variations[i]['barcode'],
                                      decoration: InputDecoration(
                                        labelText: 'Штрихкод',
                                        isDense: true,
                                        prefixIcon: Icon(PhosphorIconsRegular.barcode, color: AppColors.brandPrimary),
                                      ),
                                      onChanged: (v) => _variations[i]['barcode'] = v,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(PhosphorIconsRegular.plus),
                  label: const Text('Добавить опцию'),
                  onPressed: () {
                    setState(() {
                      _variations.add({
                        'name': '',
                        'price': 0,
                        'purchasePrice': 0,
                        'stock': 0,
                        'barcode': '',
                        'unit': 'pcs'
                      });
                    });
                  },
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Сохранить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
