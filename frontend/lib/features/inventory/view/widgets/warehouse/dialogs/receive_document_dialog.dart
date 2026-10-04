import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_event.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:kreso_frontend/core/widgets/dirty_pop_scope.dart';
import 'receive_document/receipt_row_data.dart';
import 'receive_document/receive_document_footer.dart';
import 'receive_document/receive_document_header.dart';
import 'receive_document/receive_document_tabs_bar.dart';
import 'receive_document/receive_document_meta_section.dart';
import 'receive_document/receive_document_processor.dart';
import 'receive_document/receive_document_row_callbacks.dart';
import 'receive_document/receive_document_table_section.dart';

class ReceiveDocumentDialog extends StatefulWidget {
  const ReceiveDocumentDialog({super.key});

  @override
  State<ReceiveDocumentDialog> createState() => _ReceiveDocumentDialogState();
}

class _ReceiveDocumentDialogState extends State<ReceiveDocumentDialog> {
  final _invoiceNumberController = TextEditingController();
  final _reasonController = TextEditingController();
  final _paidAmountController = TextEditingController();
  late final ValueNotifier<double> _totalSumNotifier;
  DateTime _documentDate = DateTime.now();
  int? _selectedSupplierId;
  bool _isAdHocPurchase = false;
  String _paymentStatus = 'unpaid';
  String _paymentMethod = 'cash';
  int _tabIndex = 1; // 1 = Товары витрины, 2 = Сырье

  final List<ReceiptRowData> _items = [];
  List<Ingredient> _availableIngredients = [];
  bool _isLoadingIngredients = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _totalSumNotifier = ValueNotifier<double>(0.0);
    context.read<DocumentBloc>().add(LoadSuppliers());
    _loadIngredients();
    _addItem();
  }

  @override
  void dispose() {
    for (var item in _items) {
      item.dispose();
    }
    _totalSumNotifier.dispose();
    _invoiceNumberController.dispose();
    _reasonController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  double _calculateTotal() {
    double sum = 0.0;
    for (var item in _items) {
      sum += item.quantity * item.price;
    }
    return sum;
  }

  void _updateTotal() {
    _totalSumNotifier.value = _calculateTotal();
  }

  bool get _isDirty {
    if (_invoiceNumberController.text.trim().isNotEmpty) return true;
    if (_reasonController.text.trim().isNotEmpty) return true;
    if (_selectedSupplierId != null) return true;
    if (_items.length > 1) return true;
    for (final item in _items) {
      if (item.ingredient != null) return true;
      if (item.nameController.text.trim().isNotEmpty) return true;
      if (item.price > 0 || (double.tryParse(item.priceController.text) ?? 0) > 0) return true;
      if (item.flavorController.text.trim().isNotEmpty) return true;
    }
    return false;
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
    if (_items.isEmpty || _items.every((item) => item.ingredient == null)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Внимание'),
          content: const Text('Добавьте хотя бы одну позицию из каталога.'),
          actions: [
            AppButton.primary(
              label: 'ОК',
              height: 36,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
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

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => _save(complete: true),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () => _save(complete: true),
      },
      child: Focus(
        autofocus: true,
        child: DirtyPopScope(
          isDirtyCheck: () => _isDirty,
          title: 'Отменить приходную накладную?',
          message: 'Все введенные позиции и данные документа будут сброшены. Выйти?',
          confirmLabel: 'Сбросить накладную',
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
                    color: AppColors.darkBg.withValues(alpha: 0.35),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
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
                      ReceiveDocumentTableSection(
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
                      ),
                      ReceiveDocumentFooter(
                        totalSum: _totalSumNotifier.value,
                        totalSumListenable: _totalSumNotifier,
                        currency: currency,
                        isSaving: _isSaving,
                        paymentStatus: _paymentStatus,
                        paymentMethod: _paymentMethod,
                        paidAmountController: _paidAmountController,
                        onPaymentStatusChanged: (val) => setState(() => _paymentStatus = val),
                        onPaymentMethodChanged: (val) => setState(() => _paymentMethod = val),
                        onCancel: () => Navigator.of(context).maybePop(),
                        onSaveDraft: () => _save(complete: false),
                        onSaveComplete: () => _save(complete: true),
                      ),
                    ],
                  ),
                  if (_isSaving)
                    Container(
                      color: AppColors.darkBg.withValues(alpha: 0.54),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
