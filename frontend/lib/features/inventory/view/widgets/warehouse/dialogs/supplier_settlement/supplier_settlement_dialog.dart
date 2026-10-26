// ==============================================================================
// Title: Supplier Settlement Dialog
// Path: frontend/lib/features/inventory/view/widgets/warehouse/dialogs/supplier_settlement/supplier_settlement_dialog.dart
// Description: Окно истории взаиморасчетов, акта сверки и ручных начислений по поставщику.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/core/widgets/skeleton_loader.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_event.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_state.dart';
import 'package:kreso_frontend/features/inventory/models/supplier.dart';
import 'package:kreso_frontend/features/inventory/models/supplier_transaction.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'supplier_settlement_drawer.dart';
import 'supplier_settlement_header.dart';
import 'supplier_settlement_row.dart';
import 'supplier_reconciliation_pdf_service.dart';

class SupplierSettlementDialog extends StatefulWidget {
  final Supplier supplier;
  final String currency;

  const SupplierSettlementDialog({
    super.key,
    required this.supplier,
    required this.currency,
  });

  static Future<void> show(BuildContext context, Supplier supplier, String currency) {
    return showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<DocumentBloc>()..add(LoadSupplierTransactions(supplier.id)),
        child: SupplierSettlementDialog(supplier: supplier, currency: currency),
      ),
    );
  }

  @override
  State<SupplierSettlementDialog> createState() => _SupplierSettlementDialogState();
}

class _SupplierSettlementDialogState extends State<SupplierSettlementDialog> {
  String _filter = 'all';
  SupplierTransactionType? _activeDrawerType;
  SupplierTransaction? _editingTransaction;

  Supplier _getCurrentSupplier(DocumentState state) {
    try {
      return state.suppliers.firstWhere((s) => s.id == widget.supplier.id);
    } catch (_) {
      return widget.supplier;
    }
  }

  void _openAddTransaction(SupplierTransactionType type) {
    setState(() {
      _activeDrawerType = type;
      _editingTransaction = null;
    });
  }

  void _openEditTransaction(SupplierTransaction txn) {
    setState(() {
      _activeDrawerType = txn.type;
      _editingTransaction = txn;
    });
  }

  void _closeDrawer() {
    setState(() {
      _activeDrawerType = null;
      _editingTransaction = null;
    });
  }

  Future<void> _confirmDelete(SupplierTransaction txn) async {
    final isConfirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Удалить операцию?',
      message: 'Операция на сумму ${txn.amount.toStringAsFixed(2)} ${widget.currency} будет удалена.\n'
          'Баланс поставщика автоматически скорректируется.',
      confirmLabel: 'Удалить',
      confirmIcon: PhosphorIconsRegular.trash,
      isDanger: true,
      icon: PhosphorIconsRegular.trash,
    );
    if (!mounted || isConfirmed != true) return;
    context.read<DocumentBloc>().add(DeleteSupplierTransaction(widget.supplier.id, txn.id));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.dialogRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 720),
        child: ClipRRect(
          borderRadius: AppRadii.dialogRadius,
          child: BlocBuilder<DocumentBloc, DocumentState>(
            builder: (context, state) {
              final currentSupplier = _getCurrentSupplier(state);
              final txns = state.supplierTransactions.where((t) {
                if (_filter == 'payments') return t.type == SupplierTransactionType.payment;
                if (_filter == 'invoices') return t.type == SupplierTransactionType.invoice;
                if (_filter == 'manual') {
                  return t.type == SupplierTransactionType.manualDebt ||
                      t.type == SupplierTransactionType.adjustment;
                }
                return true;
              }).toList();

              return Stack(
                children: [
                  Padding(
                    padding: AppSpacing.pXl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SupplierSettlementHeader(
                          supplier: currentSupplier,
                          currency: widget.currency,
                          activeFilter: _filter,
                          onFilterChanged: (val) => setState(() => _filter = val),
                          onDownloadPdf: () => SupplierReconciliationPdfService.downloadPdf(
                            currentSupplier,
                            state.supplierTransactions,
                            widget.currency,
                          ),
                          onClose: () => Navigator.pop(context),
                          onAddManualDebt: () => _openAddTransaction(SupplierTransactionType.manualDebt),
                          onAddPayment: () => _openAddTransaction(SupplierTransactionType.payment),
                        ),
                        const SizedBox(height: 16),
                        Expanded(child: _buildTransactionList(state, txns)),
                      ],
                    ),
                  ),
                  if (_activeDrawerType != null)
                    SupplierSettlementDrawer(
                      supplier: currentSupplier,
                      currency: widget.currency,
                      initialType: _activeDrawerType!,
                      transactionToEdit: _editingTransaction,
                      onClose: _closeDrawer,
                      onSave: (res) {
                        if (_editingTransaction != null) {
                          context.read<DocumentBloc>().add(
                                UpdateSupplierTransaction(
                                  widget.supplier.id,
                                  _editingTransaction!.id,
                                  amount: res['amount'] as double?,
                                  paymentMethod: res['payment_method'] as String?,
                                  comment: res['comment'] as String?,
                                ),
                              );
                        } else {
                          context.read<DocumentBloc>().add(
                                AddSupplierTransaction(
                                  widget.supplier.id,
                                  type: res['type'] as SupplierTransactionType,
                                  amount: res['amount'] as double,
                                  paymentMethod: res['payment_method'] as String? ?? 'cash',
                                  comment: res['comment'] as String?,
                                ),
                              );
                        }
                        _closeDrawer();
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(DocumentState state, List<SupplierTransaction> txns) {
    if (state.transactionsStatus == DocumentStatus.loading) {
      return const SkeletonList();
    }
    if (txns.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon: PhosphorIconsRegular.receipt,
          title: 'История взаиморасчетов пуста',
          description: 'Проведенные накладные, выплаты и корректировки отображаются здесь',
          size: AppEmptyStateSize.md,
        ),
      );
    }
    return ListView.separated(
      itemCount: txns.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final txn = txns[idx];
        return SupplierSettlementRow(
          transaction: txn,
          currency: widget.currency,
          onEdit: () => _openEditTransaction(txn),
          onDelete: () => _confirmDelete(txn),
        );
      },
    );
  }
}
