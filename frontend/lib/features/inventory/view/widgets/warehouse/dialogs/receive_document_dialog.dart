import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_state.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/dialogs/create_supplier_dialog.dart';
import 'package:mynix_frontend/features/pos/repository/menu_repository.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';

import 'receive_document/receipt_row_data.dart';
import 'receive_document/receive_document_header.dart';
import 'receive_document/receive_document_meta_row.dart';
import 'receive_document/receive_document_table_header.dart';
import 'receive_document/receive_document_item_row.dart';
import 'receive_document/receive_document_footer.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';


class ReceiveDocumentDialog extends StatefulWidget {
  const ReceiveDocumentDialog({super.key});

  @override
  State<ReceiveDocumentDialog> createState() => _ReceiveDocumentDialogState();
}

class _ReceiveDocumentDialogState extends State<ReceiveDocumentDialog> {
  final _invoiceNumberController = TextEditingController();
  final _reasonController = TextEditingController();
  int? _selectedSupplierId;
  
  int _tabIndex = 1; // 1 = Товары витрины, 2 = Сырье
  int? _selectedParentId;
  int? _selectedChildId;

  final List<ReceiptRowData> _items = [];
  List<Ingredient> _availableIngredients = [];
  bool _isLoadingIngredients = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    context.read<DocumentBloc>().add(LoadSuppliers());
    _loadIngredients();
    _addItem();
  }
  
  @override
  void dispose() {
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadIngredients() async {
    try {
      final repo = context.read<InventoryRepository>();
      final ingredients = await repo.getIngredients();
      final retail = await repo.getRetailProducts();
      if (mounted) {
        setState(() {
          _availableIngredients = [...ingredients, ...retail];
          _isLoadingIngredients = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingIngredients = false);
    }
  }

  void _addItem() {
    setState(() {
      _items.add(ReceiptRowData());
    });
    _focusRow(_items.last.nameFocusNode);
  }

  void _focusRow(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (node.canRequestFocus) {
        node.requestFocus();
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _save({required bool complete}) async {
    if (_items.isEmpty || _items.every((item) => item.ingredient == null && item.newName.trim().isEmpty)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Внимание'),
          content: const Text('Добавьте хотя бы одну позицию.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ОК'))],
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    double getConversionFactor(String fromUnit, String toUnit) {
      if (fromUnit == toUnit) return 1.0;
      if (fromUnit == 'кг' && toUnit == 'г') return 1000.0;
      if (fromUnit == 'г' && toUnit == 'кг') return 0.001;
      if (fromUnit == 'л' && toUnit == 'мл') return 1000.0;
      if (fromUnit == 'мл' && toUnit == 'л') return 0.001;
      return 1.0;
    }

    try {
      final repo = context.read<InventoryRepository>();
      final menuRepo = context.read<MenuRepository>();
      final categoryId = _selectedChildId ?? _selectedParentId;

      List<Map<String, dynamic>> docItems = [];

      for (var item in _items) {
        int? finalIngredientId;
        int? finalRetailProductId;
        
        if (item.ingredient != null) {
          final isRetail = item.ingredient!.attributes?['is_retail'] == true;
          if (isRetail) {
            finalRetailProductId = item.ingredient!.id;
          } else {
            finalIngredientId = item.ingredient!.id;
          }
        } else if (item.newName.trim().isNotEmpty) {
          if (categoryId == null) {
            throw Exception('Не выбрана категория для новых товаров ("${item.newName}"). Укажите категорию сверху.');
          }
          String unitKey = 'pcs';
          switch (item.selectedUnit) {
            case 'кг': unitKey = 'kg'; break;
            case 'г': unitKey = 'g'; break;
            case 'л': unitKey = 'l'; break;
            case 'мл': unitKey = 'ml'; break;
            case 'шт':
            case 'порц':
            default:
              unitKey = 'pcs'; break;
          }

          if (_tabIndex == 1) { // Retail
            final Map<String, dynamic> attributes = {};
            final flavor = item.flavorController.text.trim();
            final volume = item.volumeController.text.trim();
            if (flavor.isNotEmpty) attributes['Вкус'] = flavor;
            if (volume.isNotEmpty) attributes['Объем'] = '$volume ${item.selectedUnit}'.trim();

            finalRetailProductId = await menuRepo.createRetailProduct(
              name: item.newName.trim(),
              categoryId: categoryId,
              unit: unitKey,
              purchasePrice: item.price,
              sellingPrice: item.price,
              attributes: attributes.isNotEmpty ? attributes : null,
              initialStock: 0,
            );
          } else { // Ingredient
            finalIngredientId = await repo.createIngredient(
              name: item.newName.trim(),
              unit: unitKey,
              minStockAlert: 0,
              costPerUnit: item.price,
              categoryId: categoryId,
              initialStock: 0,
            );
          }
        } else {
          continue; // skip empty rows
        }

        double factor = 1.0;
        if (item.ingredient != null) {
          factor = getConversionFactor(item.selectedUnit, item.ingredient!.unit);
        }

        final dbQuantity = item.quantity * factor;
        final dbPricePerUnit = item.price / factor;

        docItems.add({
          'ingredient_id': finalIngredientId,
          'retail_product_id': finalRetailProductId,
          'quantity': dbQuantity,
          'price_per_unit': dbPricePerUnit,
          'total_price': dbQuantity * dbPricePerUnit,
        });
      }

      if (docItems.isEmpty) {
        throw Exception('Нет товаров для прихода');
      }

      final data = {
        'type': 'receipt',
        'supplier_id': _selectedSupplierId,
        'invoice_number': _invoiceNumberController.text,
        'reason': _reasonController.text,
        'items': docItems,
        'status': complete ? 'completed' : 'draft',
      };

      if (mounted) {
        context.read<DocumentBloc>().add(CreateDocument(data));
        Navigator.of(context).pop();
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
         setState(() => _isSaving = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsBloc>().state.currency;
    final width = MediaQuery.of(context).size.width * 0.95;
    final height = MediaQuery.of(context).size.height * 0.95;
    
    double totalSum = 0;
    for (var item in _items) {
      totalSum += item.quantity * item.price;
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => _save(complete: true),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () => _save(complete: true),
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: width,
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    ReceiveDocumentHeader(onClose: () => Navigator.of(context).pop()),
                    
                    BlocBuilder<DocumentBloc, DocumentState>(
                      builder: (context, state) {
                        return ReceiveDocumentMetaRow(
                          suppliers: state.suppliers,
                          selectedSupplierId: _selectedSupplierId,
                          onSupplierChanged: (val) => setState(() => _selectedSupplierId = val),
                          onAddSupplier: () async {
                            final result = await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (context) => const CreateSupplierDialog(),
                            );
                            if (result != null && mounted) {
                              context.read<DocumentBloc>().add(
                                CreateSupplier(result['name'], contactInfo: result['contact_info']),
                              );
                            }
                          },
                          invoiceController: _invoiceNumberController,
                          reasonController: _reasonController,
                          tabIndex: _tabIndex,
                          onTabChanged: (val) => setState(() => _tabIndex = val),
                          selectedParentId: _selectedParentId,
                          selectedChildId: _selectedChildId,
                          onParentChanged: (val) => setState(() => _selectedParentId = val),
                          onChildChanged: (val) => setState(() => _selectedChildId = val),
                        );
                      }
                    ),
                    
                    ReceiveDocumentTableHeader(currency: currency, tabIndex: _tabIndex),

                    Expanded(
                      child: _isLoadingIngredients
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              itemCount: _items.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return ReceiveDocumentItemRow(
                                  item: item,
                                  index: index,
                                  isLast: index == _items.length - 1,
                                  availableIngredients: _availableIngredients,
                                  tabIndex: _tabIndex,
                                  onIngredientSelected: (selection) {
                                    setState(() {
                                      item.ingredient = selection;
                                      item.newName = selection.name;
                                      item.price = selection.costPerUnit;
                                      item.priceController.text = item.price.toString();
                                      if (['шт', 'л', 'мл', 'кг', 'г', 'порц'].contains(selection.unit)) {
                                        item.selectedUnit = selection.unit;
                                      } else {
                                        item.selectedUnit = 'шт';
                                      }
                                      _focusRow(item.qtyFocusNode);
                                    });
                                  },
                                  onNameChanged: (val) {
                                    item.newName = val;
                                    if (item.ingredient?.name != val) {
                                      setState(() {
                                        item.ingredient = null;
                                      });
                                    }
                                  },
                                  onNameSubmitted: () {
                                    if (_tabIndex == 1) {
                                      _focusRow(item.flavorFocusNode);
                                    } else {
                                      _focusRow(item.qtyFocusNode);
                                    }
                                  },
                                  onFlavorSubmitted: () => _focusRow(item.volumeFocusNode),
                                  onVolumeSubmitted: () => _focusRow(item.qtyFocusNode),
                                  onQtySubmitted: () => _focusRow(item.minStockAlertFocusNode),
                                  onMinStockAlertSubmitted: () => _focusRow(item.priceFocusNode),
                                  onPriceSubmitted: () => _focusRow(item.sellPriceFocusNode),
                                  onSellPriceSubmitted: () {
                                    if (index == _items.length - 1) {
                                      _addItem();
                                    } else {
                                      _focusRow(_items[index + 1].nameFocusNode);
                                    }
                                  },
                                  onUnitChanged: (val) {
                                    if (val != null) setState(() => item.selectedUnit = val);
                                  },
                                  onQtyChanged: (val) {
                                    final num = double.tryParse(val);
                                    if (num != null) setState(() => item.quantity = num);
                                  },
                                  onMinStockAlertChanged: (val) {
                                    final num = double.tryParse(val);
                                    if (num != null) setState(() => item.minStockAlert = num);
                                  },
                                  onPriceChanged: (val) {
                                    final num = double.tryParse(val);
                                    if (num != null) setState(() => item.price = num);
                                  },
                                  onSellPriceChanged: (val) {
                                    final num = double.tryParse(val);
                                    if (num != null) setState(() => item.sellPrice = num);
                                  },
                                  onRemove: () => _removeItem(index),
                                );
                              },
                            ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(PhosphorIconsRegular.plus),
                            label: const Text('Добавить строку (Enter)'),
                          ),
                        ],
                      ),
                    ),

                    ReceiveDocumentFooter(
                      totalSum: totalSum,
                      currency: currency,
                      isSaving: _isSaving,
                      onCancel: () => Navigator.of(context).pop(),
                      onSaveDraft: () => _save(complete: false),
                      onSaveComplete: () => _save(complete: true),
                    ),
                  ],
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
