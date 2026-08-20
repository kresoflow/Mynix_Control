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
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

import 'receive_document/receipt_row_data.dart';
import 'receive_document/receive_document_header.dart';
import 'receive_document/receive_document_meta_row.dart';
import 'receive_document/receive_document_table_header.dart';
import 'receive_document/receive_document_footer.dart';
import 'receive_document/receive_document_processor.dart';
import 'receive_document/receive_document_items_list.dart';
import 'receive_document/receive_document_unit_helper.dart';

class ReceiveDocumentDialog extends StatefulWidget {
  const ReceiveDocumentDialog({super.key});

  @override
  State<ReceiveDocumentDialog> createState() => _ReceiveDocumentDialogState();
}

class _ReceiveDocumentDialogState extends State<ReceiveDocumentDialog> {
  final _invoiceNumberController = TextEditingController();
  final _reasonController = TextEditingController();
  final _paidAmountController = TextEditingController();
  DateTime _documentDate = DateTime.now();
  int? _selectedSupplierId;
  bool _isAdHocPurchase = false;
  String _paymentStatus = 'unpaid';
  String _paymentMethod = 'cash';

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
    _invoiceNumberController.dispose();
    _reasonController.dispose();
    _paidAmountController.dispose();
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
    setState(() => _items.add(ReceiptRowData()));
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

  void _onRowIngredientSelected(int index, Ingredient selection) {
    setState(() {
      final item = _items[index];
      item.ingredient = selection;
      item.nameController.text = selection.name;
      item.price = selection.costPerUnit;
      item.priceController.text = selection.costPerUnit.toStringAsFixed(2);
      item.selectedUnit = ReceiveDocumentUnitHelper.normalizeUnit(selection.unit);
      item.minStockAlert = selection.minStockAlert;
      item.minStockAlertController.text = selection.minStockAlert.toInt().toString();

      if (selection.attributes != null) {
        final flavor = selection.attributes!['Вкус'] ?? '';
        final vol = selection.attributes!['Объем'] ?? '';
        item.flavorController.text = flavor;
        item.volumeController.text = vol.replaceAll(RegExp(r'[^0-9.]'), '');
      }
    });
    _focusRow(_items[index].qtyFocusNode);
  }

  void _onRowNameChanged(int index, String val) {
    final item = _items[index];
    item.newName = val;
    if (item.ingredient != null && item.ingredient!.name != val) {
      setState(() => item.ingredient = null);
    }
  }

  void _onRowNameSubmitted(int index) {
    if (_tabIndex == 1) {
      _focusRow(_items[index].flavorFocusNode);
    } else {
      _focusRow(_items[index].qtyFocusNode);
    }
  }

  void _onRowSellPriceSubmitted(int index) {
    if (index == _items.length - 1) {
      _addItem();
    } else {
      _focusRow(_items[index + 1].nameFocusNode);
    }
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
    try {
      final supplierId = _selectedSupplierId == -1 ? null : _selectedSupplierId;
      final paidAmt = _paymentStatus == 'paid'
          ? 0.0
          : (_paymentStatus == 'partial' ? (double.tryParse(_paidAmountController.text) ?? 0.0) : 0.0);

      await ReceiveDocumentProcessor.saveDocument(
        context: context,
        items: _items,
        selectedSupplierId: supplierId,
        invoiceNumber: _invoiceNumberController.text,
        reason: _reasonController.text,
        documentDate: _documentDate,
        tabIndex: _tabIndex,
        categoryId: _selectedChildId ?? _selectedParentId,
        paymentStatus: _paymentStatus,
        paidAmount: paidAmt,
        paymentMethod: _paymentMethod,
        complete: complete,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
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
                      builder: (blocCtx, state) {
                        return ReceiveDocumentMetaRow(
                          suppliers: state.suppliers,
                          selectedSupplierId: _selectedSupplierId,
                          onSupplierChanged: (val) => setState(() => _selectedSupplierId = val),
                          onAddSupplier: () async {
                            final result = await showDialog<Map<String, dynamic>>(
                              context: blocCtx,
                              builder: (dialogCtx) => const CreateSupplierDialog(),
                            );
                            if (result != null && blocCtx.mounted) {
                              blocCtx.read<DocumentBloc>().add(
                                CreateSupplier(result['name'], contactInfo: result['contact_info']),
                              );
                            }
                          },
                          invoiceController: _invoiceNumberController,
                          reasonController: _reasonController,
                          documentDate: _documentDate,
                          onDateChanged: (val) => setState(() => _documentDate = val),
                          tabIndex: _tabIndex,
                          onTabChanged: (val) => setState(() => _tabIndex = val),
                          selectedParentId: _selectedParentId,
                          selectedChildId: _selectedChildId,
                          onParentChanged: (val) => setState(() {
                            _selectedParentId = val;
                            _selectedChildId = null;
                          }),
                          onChildChanged: (val) => setState(() => _selectedChildId = val),
                          isAdHocPurchase: _isAdHocPurchase,
                          onAdHocChanged: (val) => setState(() => _isAdHocPurchase = val),
                        );
                      },
                    ),
                    ReceiveDocumentTableHeader(currency: currency, tabIndex: _tabIndex),
                    Expanded(
                      child: ReceiveDocumentItemsList(
                        isLoading: _isLoadingIngredients,
                        items: _items,
                        availableIngredients: _availableIngredients,
                        tabIndex: _tabIndex,
                        onIngredientSelected: _onRowIngredientSelected,
                        onNameChanged: _onRowNameChanged,
                        onNameSubmitted: _onRowNameSubmitted,
                        onFlavorSubmitted: (i) => _focusRow(_items[i].volumeFocusNode),
                        onVolumeSubmitted: (i) => _focusRow(_items[i].qtyFocusNode),
                        onQtySubmitted: (i) => _focusRow(_items[i].minStockAlertFocusNode),
                        onMinStockAlertSubmitted: (i) => _focusRow(_items[i].priceFocusNode),
                        onPriceSubmitted: (i) => _focusRow(_items[i].sellPriceFocusNode),
                        onSellPriceSubmitted: _onRowSellPriceSubmitted,
                        onUnitChanged: (i, val) { if (val != null) setState(() => _items[i].selectedUnit = val); },
                        onQtyChanged: (i, val) { final n = double.tryParse(val); if (n != null) setState(() => _items[i].quantity = n); },
                        onMinStockAlertChanged: (i, val) { final n = double.tryParse(val); if (n != null) setState(() => _items[i].minStockAlert = n); },
                        onPriceChanged: (i, val) { final n = double.tryParse(val); if (n != null) setState(() => _items[i].price = n); },
                        onSellPriceChanged: (i, val) { final n = double.tryParse(val); if (n != null) setState(() => _items[i].sellPrice = n); },
                        onRemove: _removeItem,
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
                      paymentStatus: _paymentStatus,
                      paymentMethod: _paymentMethod,
                      paidAmountController: _paidAmountController,
                      onPaymentStatusChanged: (val) => setState(() => _paymentStatus = val),
                      onPaymentMethodChanged: (val) => setState(() => _paymentMethod = val),
                      onCancel: () => Navigator.of(context).pop(),
                      onSaveDraft: () => _save(complete: false),
                      onSaveComplete: () => _save(complete: true),
                    ),
                  ],
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
