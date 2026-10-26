import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

import 'retail/retail_single_product_form.dart';
import 'retail/retail_variations_editor.dart';
import 'retail/retail_category_selector.dart';

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
  late TextEditingController _flavorController;

  int? _selectedCategoryId;
  String _selectedUnit = 'pcs';
  bool _hasVariations = false;
  final List<Map<String, dynamic>> _variations = [];

  final Map<String, String> _units = {
    'l': 'л',
    'ml': 'мл',
    'kg': 'кг',
    'g': 'г',
    'pcs': 'шт',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _purchasePriceController = TextEditingController();
    _sellingPriceController = TextEditingController();
    _initialStockController = TextEditingController(text: '0');
    _barcodeController = TextEditingController();
    _flavorController = TextEditingController();
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
        final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0.0;
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
        const SnackBar(content: Text('Пожалуйста, заполните все поля корректно')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSaveShortcutScope(
      onSave: _submit,
      onCancel: () => Navigator.of(context).pop(),
      child: Dialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
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
                validator: (v) => v == null || v.isEmpty ? 'Обязательное поле' : null,
              ),
              const SizedBox(height: 16),
              RetailCategorySelector(
                selectedCategoryId: _selectedCategoryId,
                onCategoryChanged: (val) => setState(() => _selectedCategoryId = val),
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
                        'unit': 'pcs',
                      });
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              if (!_hasVariations)
                RetailSingleProductForm(
                  selectedUnit: _selectedUnit,
                  onUnitChanged: (val) => setState(() => _selectedUnit = val),
                  initialStockController: _initialStockController,
                  purchasePriceController: _purchasePriceController,
                  sellingPriceController: _sellingPriceController,
                  barcodeController: _barcodeController,
                  units: _units,
                )
              else
                RetailVariationsEditor(
                  flavorController: _flavorController,
                  variations: _variations,
                  units: _units,
                  onAddVariation: () {
                    setState(() {
                      _variations.add({
                        'name': '',
                        'price': 0,
                        'purchasePrice': 0,
                        'stock': 0,
                        'barcode': '',
                        'unit': 'pcs',
                      });
                    });
                  },
                  onRemoveVariation: (i) => setState(() => _variations.removeAt(i)),
                  onStateChanged: () => setState(() {}),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppGhostButton(
                    onPressed: () => Navigator.of(context).pop(),
                    label: 'Отмена',
                  ),
                  const SizedBox(width: 16),
                  AppPrimaryButton(
                    onPressed: _submit,
                    label: 'Сохранить',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
