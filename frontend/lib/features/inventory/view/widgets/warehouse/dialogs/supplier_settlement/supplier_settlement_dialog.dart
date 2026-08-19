import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/skeleton_loader.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_state.dart';
import 'package:mynix_frontend/features/inventory/models/supplier.dart';
import 'package:mynix_frontend/features/inventory/models/supplier_transaction.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'supplier_payment_modal.dart';
import 'edit_transaction_modal.dart';
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

  Supplier _getCurrentSupplier(DocumentState state) {
    try {
      return state.suppliers.firstWhere((s) => s.id == widget.supplier.id);
    } catch (_) {
      return widget.supplier;
    }
  }

  Future<void> _openAddTransaction(BuildContext context, SupplierTransactionType type) async {
    final currentSupplier = _getCurrentSupplier(context.read<DocumentBloc>().state);
    final res = await SupplierPaymentModal.show(
      context,
      supplier: currentSupplier,
      currency: widget.currency,
      initialType: type,
    );
    if (res != null && mounted) {
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
  }

  Future<void> _openEditTransaction(BuildContext context, SupplierTransaction txn) async {
    final res = await EditTransactionModal.show(
      context,
      transaction: txn,
      currency: widget.currency,
    );
    if (res != null && mounted) {
      context.read<DocumentBloc>().add(
            UpdateSupplierTransaction(
              widget.supplier.id,
              txn.id,
              amount: res['amount'] as double?,
              paymentMethod: res['payment_method'] as String?,
              comment: res['comment'] as String?,
            ),
          );
    }
  }

  void _confirmDelete(BuildContext context, SupplierTransaction txn) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить операцию?'),
        content: Text(
          'Операция на сумму ${txn.amount.toStringAsFixed(2)} ${widget.currency} будет удалена.\n'
          'Баланс поставщика автоматически скорректируется.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.pop(dCtx);
              context.read<DocumentBloc>().add(DeleteSupplierTransaction(widget.supplier.id, txn.id));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocBuilder<DocumentBloc, DocumentState>(
            builder: (context, state) {
              final currentSupplier = _getCurrentSupplier(state);
              final txns = state.supplierTransactions.where((t) {
                if (_filter == 'payments') return t.type == SupplierTransactionType.payment;
                if (_filter == 'invoices') return t.type == SupplierTransactionType.invoice;
                if (_filter == 'manual') return t.type == SupplierTransactionType.manualDebt || t.type == SupplierTransactionType.adjustment;
                return true;
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, currentSupplier, state.supplierTransactions),
                  const SizedBox(height: 16),
                  _buildToolbar(context),
                  const SizedBox(height: 16),
                  Expanded(child: _buildTransactionList(state, txns)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Supplier supplier, List<SupplierTransaction> allTxns) {
    final hasDebt = supplier.balance < 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(PhosphorIconsRegular.wallet, color: AppColors.brandPrimary, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(supplier.name, style: AppTextStyles.h2.copyWith(color: AppColors.darkText)),
                const SizedBox(height: 2),
                Text(
                  hasDebt
                      ? 'Текущий долг: ${supplier.balance.abs().toStringAsFixed(2)} ${widget.currency}'
                      : 'Баланс: +${supplier.balance.toStringAsFixed(2)} ${widget.currency} (Аванс)',
                  style: AppTextStyles.caption.copyWith(
                    color: hasDebt ? AppColors.danger : AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            AppButton(
              label: 'Акт сверки (PDF)',
              icon: PhosphorIconsRegular.filePdf,
              variant: AppButtonVariant.secondary,
              onPressed: () => SupplierReconciliationPdfService.downloadPdf(supplier, allTxns, widget.currency),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(PhosphorIconsRegular.x, color: AppColors.darkSubtext, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildFilterChip('all', 'Все'),
            const SizedBox(width: 6),
            _buildFilterChip('invoices', 'Накладные'),
            const SizedBox(width: 6),
            _buildFilterChip('payments', 'Выплаты'),
            const SizedBox(width: 6),
            _buildFilterChip('manual', 'Ручные'),
          ],
        ),
        Row(
          children: [
            AppButton(
              label: 'Начислить долг',
              icon: PhosphorIconsRegular.plus,
              variant: AppButtonVariant.secondary,
              onPressed: () => _openAddTransaction(context, SupplierTransactionType.manualDebt),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: 'Внести оплату',
              icon: PhosphorIconsRegular.money,
              variant: AppButtonVariant.primary,
              onPressed: () => _openAddTransaction(context, SupplierTransactionType.payment),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final isSelected = _filter == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = id),
      selectedColor: AppColors.brandPrimary.withValues(alpha: 0.2),
      labelStyle: AppTextStyles.caption.copyWith(
        color: isSelected ? AppColors.brandPrimary : AppColors.darkSubtext,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: AppColors.darkCard,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildTransactionList(DocumentState state, List<SupplierTransaction> txns) {
    if (state.transactionsStatus == DocumentStatus.loading) {
      return const SkeletonList();
    }
    if (txns.isEmpty) {
      return Center(
        child: Text('История взаиморасчетов пуста', style: TextStyle(color: AppColors.darkSubtext)),
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
          onEdit: () => _openEditTransaction(context, txn),
          onDelete: () => _confirmDelete(context, txn),
        );
      },
    );
  }
}
