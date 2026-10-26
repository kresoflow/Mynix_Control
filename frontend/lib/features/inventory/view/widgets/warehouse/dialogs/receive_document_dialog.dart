import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/widgets/app_save_shortcut_scope.dart';
import 'package:kreso_frontend/core/widgets/app_toast.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_event.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:kreso_frontend/core/widgets/dirty_pop_scope.dart';
import 'receive_document/category_mode/receive_category_section.dart';
import 'receive_document/category_mode/receive_category_sync_adapter.dart';
import 'receive_document/receipt_row_data.dart';
import 'receive_document/receive_document_cart_sheet.dart';
import 'receive_document/receive_document_footer.dart';
import 'receive_document/receive_document_header.dart';
import 'receive_document/receive_document_tabs_bar.dart';
import 'receive_document/receive_document_meta_section.dart';
import 'receive_document/receive_document_processor.dart';
import 'receive_document/receive_document_row_callbacks.dart';
import 'receive_document/receive_document_table_section.dart';

class ReceiveDocumentDialog extends StatefulWidget {
  final InventoryDocument? initialDocument;

  const ReceiveDocumentDialog({super.key, this.initialDocument});

  @override
  State<ReceiveDocumentDialog> createState() => _ReceiveDocumentDialogState();
}

class _ReceiveDocumentDialogState extends State<ReceiveDocumentDialog> {
  final _invoiceNumberController = TextEditingController();
  final _reasonController = TextEditingController();
  final _paidAmountController = TextEditingController();
  late final ValueNotifier<double> _totalSumNotifier;
  late final ValueNotifier<int> _cartCountNotifier;
  late final ReceiveCategorySyncAdapter _categoryAdapter;
  DateTime _documentDate = DateTime.now();
  int? _selectedSupplierId;
  bool _isAdHocPurchase = false;
  String _paymentStatus = 'unpaid';
  String _paymentMethod = 'cash';
  int _tabIndex = 0; // 0 = Все, 1 = Товары витрины, 2 = Сырье
  ReceiveViewMode _viewMode = ReceiveViewMode.lines;
  bool _isCartOpen = false;

  final List<ReceiptRowData> _items = [];
  List<Ingredient> _availableIngredients = [];
  bool _isLoadingIngredients = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _totalSumNotifier = ValueNotifier<double>(0.0);
    _cartCountNotifier = ValueNotifier<int>(0);
    _categoryAdapter = ReceiveCategorySyncAdapter(items: _items, onTotalChanged: _updateTotal);
    context.read<DocumentBloc>().add(const LoadSuppliers());
    _loadIngredients();
    if (widget.initialDocument != null) {
      _initFromDraft(widget.initialDocument!);
    } else {
      _addItem();
    }
  }

  void _initFromDraft(InventoryDocument doc) {
    _invoiceNumberController.text = doc.invoiceNumber ?? '';
    _reasonController.text = doc.reason ?? '';
    _selectedSupplierId = doc.supplierId;
    _documentDate = doc.date;
    _paymentStatus = doc.paymentStatus;
    _paymentMethod = doc.paymentMethod;
    if (doc.paidAmount > 0) _paidAmountController.text = doc.paidAmount.toStringAsFixed(2);
    _items.addAll(ReceiveDocumentProcessor.createDraftRows(doc.items));
    _updateTotal();
  }

  @override
  void dispose() {
    for (var item in _items) { item.dispose(); }
    _totalSumNotifier.dispose();
    _cartCountNotifier.dispose();
    _invoiceNumberController.dispose();
    _reasonController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  double _calculateTotal() => _items.fold(0.0, (sum, it) => sum + (it.quantity * it.price));
  int _calculateCartCount() => _items.where((r) => r.ingredient != null && r.quantity > 0 && r.price > 0).length;
  void _updateTotal() {
    final t = _calculateTotal();
    _totalSumNotifier.value = t;
    _cartCountNotifier.value = _calculateCartCount();
    if (_paymentStatus == 'paid' && t > 0) _paidAmountController.text = t.toStringAsFixed(2);
  }

  void _onPaymentStatusChanged(String val) {
    setState(() {
      _paymentStatus = val;
      if (val == 'paid' && _totalSumNotifier.value > 0) {
        _paidAmountController.text = _totalSumNotifier.value.toStringAsFixed(2);
      } else if (val == 'unpaid') {
        _paidAmountController.clear();
      }
    });
  }

  bool get _isDirty {
    if (_invoiceNumberController.text.trim().isNotEmpty || _reasonController.text.trim().isNotEmpty) return true;
    if (_selectedSupplierId != null || _items.length > 1) return true;
    return _items.any((i) => i.ingredient != null || i.nameController.text.trim().isNotEmpty || i.price > 0);
  }

  Future<void> _loadIngredients() async {
    try {
      final repo = context.read<InventoryRepository>();
      final ingredients = await repo.getIngredients();
      final retail = await repo.getRetailProducts();
      if (mounted) {
        setState(() {
          _availableIngredients = [...ingredients, ...retail].where((i) => !i.isArchived).toList();
          _isLoadingIngredients = false;
          ReceiveDocumentProcessor.bindDraftIngredients(_items, _availableIngredients, widget.initialDocument?.items);
          _updateTotal();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingIngredients = false);
    }
  }

  void _addItem() {
    setState(() => _items.add(ReceiptRowData()));
    _updateTotal();
    ReceiveDocumentRowCallbacks.focusRow(_items.last.nameFocusNode);
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
    _updateTotal();
  }

  Future<void> _save({required bool complete}) async {
    _categoryAdapter.pruneEmptyRows();
    if (_items.isEmpty || _items.every((item) => item.ingredient == null || item.quantity <= 0)) {
      AppToast.showError(context, 'Добавьте хотя бы одну позицию с ненулевым количеством');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final supplierId = _selectedSupplierId == -1 ? null : _selectedSupplierId;
      final enteredAmt = double.tryParse(_paidAmountController.text) ?? 0.0;
      final paidAmt = _paymentStatus == 'unpaid' ? 0.0 : (_paymentStatus == 'paid' ? (_totalSumNotifier.value > 0 ? _totalSumNotifier.value : enteredAmt) : enteredAmt);
      await ReceiveDocumentProcessor.saveDocument(
        context: context, items: _items, selectedSupplierId: supplierId,
        invoiceNumber: _invoiceNumberController.text, reason: _reasonController.text,
        documentDate: _documentDate, tabIndex: _tabIndex, paymentStatus: _paymentStatus,
        paidAmount: paidAmt, paymentMethod: _paymentMethod, complete: complete,
        documentId: widget.initialDocument?.id,
      );
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

    return AppSaveShortcutScope(
      onSave: () => _save(complete: true),
      onCancel: () => Navigator.of(context).maybePop(),
      child: DirtyPopScope(
          isDirtyCheck: () => _isDirty,
          title: 'Отменить приходную накладную?',
          message: 'Все введенные позиции и данные документа будут сброшены. Выйти?',
          confirmLabel: 'Сбросить накладную',
          child: Dialog(
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.dialogRadius),
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: Container(
              width: width, height: height,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: AppRadii.dialogRadius,
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                boxShadow: AppShadows.dialog,
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      ReceiveDocumentHeader(onClose: () => Navigator.of(context).maybePop()),
                      const SizedBox(height: 14),
                      ReceiveDocumentTabsBar(
                        tabIndex: _tabIndex,
                        onTabSelected: (val) => setState(() => _tabIndex = val),
                        viewMode: _viewMode,
                        onViewModeChanged: (mode) => setState(() => _viewMode = mode),
                        onAddRow: _addItem,
                      ),
                      const SizedBox(height: 6),
                      ReceiveDocumentMetaSection(
                        selectedSupplierId: _selectedSupplierId,
                        onSupplierChanged: (val) => setState(() => _selectedSupplierId = val),
                        invoiceController: _invoiceNumberController,
                        reasonController: _reasonController,
                        documentDate: _documentDate,
                        onDateChanged: (val) => setState(() => _documentDate = val),
                        isAdHocPurchase: _isAdHocPurchase,
                        onAdHocChanged: (val) => setState(() => _isAdHocPurchase = val),
                      ),
                      _viewMode == ReceiveViewMode.lines
                          ? ReceiveDocumentTableSection(
                              isLoading: _isLoadingIngredients,
                              items: _items,
                              availableIngredients: _availableIngredients,
                              tabIndex: _tabIndex,
                              currency: currency,
                              totalSumNotifier: _totalSumNotifier,
                              onAddItem: _addItem,
                              onRemoveItem: _removeItem,
                              onTotalChanged: _updateTotal,
                              onStateUpdate: (fn) => setState(fn),
                            )
                          : ReceiveCategorySection(
                              availableIngredients: _availableIngredients.where((i) => _tabIndex == 1 ? i.isRetail : (_tabIndex == 2 ? !i.isRetail : true)).toList(),
                              isRetail: _tabIndex == 1,
                              currency: currency,
                              adapter: _categoryAdapter,
                            ),
                      ReceiveDocumentFooter(
                        totalSum: _totalSumNotifier.value,
                        totalSumListenable: _totalSumNotifier,
                        cartCountListenable: _cartCountNotifier,
                        cartItemCount: _calculateCartCount(),
                        currency: currency,
                        isSaving: _isSaving,
                        paymentStatus: _paymentStatus,
                        paymentMethod: _paymentMethod,
                        paidAmountController: _paidAmountController,
                        onPaymentStatusChanged: _onPaymentStatusChanged,
                        onPaymentMethodChanged: (val) => setState(() => _paymentMethod = val),
                        isCartOpen: _isCartOpen,
                        onToggleCart: () => setState(() => _isCartOpen = !_isCartOpen),
                        onCancel: () => Navigator.of(context).maybePop(),
                        onSaveDraft: () => _save(complete: false),
                        onSaveComplete: () => _save(complete: true),
                      ),
                    ],
                  ),
                  if (_isCartOpen)
                    ReceiveDocumentCartSheet(
                      items: _items,
                      adapter: _categoryAdapter,
                      currency: currency,
                      onClose: () => setState(() => _isCartOpen = false),
                      onStateUpdate: () => setState(() => _updateTotal()),
                    ),
                  if (_isSaving)
                    Container(color: AppColors.darkBg.withValues(alpha: 0.54), child: const Center(child: CircularProgressIndicator())),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
