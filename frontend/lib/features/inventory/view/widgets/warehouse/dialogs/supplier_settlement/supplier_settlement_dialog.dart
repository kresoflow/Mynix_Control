// ==============================================================================
// Title: Supplier Settlement Dialog
// Path: frontend/lib/features/inventory/view/widgets/warehouse/dialogs/supplier_settlement/supplier_settlement_dialog.dart
// Description: Окно истории взаиморасчетов, акта сверки и ручных начислений по поставщику.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_spacing.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/core/widgets/skeleton_loader.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_event.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_state.dart';
import 'package:kreso_frontend/features/inventory/models/supplier.dart';
import 'package:kreso_frontend/features/inventory/models/supplier_transaction.dart';
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

  Future<void> _confirmDelete(BuildContext context, SupplierTransaction txn) async {
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
    if (isConfirmed == true && mounted) {
      context.read<DocumentBloc>().add(DeleteSupplierTransaction(widget.supplier.id, txn.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.dialogRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: Padding(
          padding: AppSpacing.pXl,
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, currentSupplier, state.supplierTransactions, isDark),
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

  Widget _buildHeader(BuildContext context, Supplier supplier, List<SupplierTransaction> allTxns, bool isDark) {
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
                borderRadius: AppRadii.inputRadius,
              ),
              child: const Icon(PhosphorIconsRegular.wallet, color: AppColors.brandPrimary, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier.name,
                  style: AppTextStyles.h2.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
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
              icon: Icon(
                PhosphorIconsRegular.x,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                size: 22,
              ),
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
        AppSegmentedControl<String>(
          selectedValue: _filter,
          size: AppSegmentedSize.sm,
          onValueChanged: (val) => setState(() => _filter = val),
          items: const [
            AppSegmentedItem(value: 'all', label: 'Все'),
            AppSegmentedItem(value: 'invoices', label: 'Накладные'),
            AppSegmentedItem(value: 'payments', label: 'Выплаты'),
            AppSegmentedItem(value: 'manual', label: 'Ручные'),
          ],
        ),
        Row(
          children: [
            AppSecondaryButton(
              label: 'Начислить долг',
              icon: PhosphorIconsRegular.plus,
              size: AppButtonSize.sm,
              onPressed: () => _openAddTransaction(context, SupplierTransactionType.manualDebt),
            ),
            const SizedBox(width: 8),
            AppPrimaryButton(
              label: 'Внести оплату',
              icon: PhosphorIconsRegular.money,
              size: AppButtonSize.sm,
              onPressed: () => _openAddTransaction(context, SupplierTransactionType.payment),
            ),
          ],
        ),
      ],
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
          onEdit: () => _openEditTransaction(context, txn),
          onDelete: () => _confirmDelete(context, txn),
        );
      },
    );
  }
}
