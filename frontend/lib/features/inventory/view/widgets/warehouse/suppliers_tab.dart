import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_event.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_state.dart';
import 'package:kreso_frontend/features/inventory/models/supplier.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/create_supplier_dialog.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/edit_supplier_dialog.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/supplier_settlement/supplier_settlement_dialog.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/supplier_payment_dialog.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/skeleton_loader.dart';
import 'supplier_row.dart';
import 'suppliers_table_header.dart';

export 'supplier_row.dart';

class SuppliersTab extends StatefulWidget {
  const SuppliersTab({super.key});

  @override
  State<SuppliersTab> createState() => _SuppliersTabState();
}

class _SuppliersTabState extends State<SuppliersTab> {
  String _searchQuery = '';
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    context.read<DocumentBloc>().add(LoadSuppliers());
  }

  Future<void> _openCreate(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreateSupplierDialog(),
    );
    if (result != null && context.mounted) {
      context.read<DocumentBloc>().add(
        CreateSupplier(
          result['name'],
          contactInfo: result['contact_info'],
          initialBalance: result['initial_balance'] != null ? double.tryParse(result['initial_balance'].toString()) : null,
        ),
      );
    }
  }

  Future<void> _openEdit(BuildContext ctx, Supplier supplier) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: ctx,
      builder: (_) => EditSupplierDialog(supplier: supplier),
    );
    if (result != null && ctx.mounted) {
      ctx.read<DocumentBloc>().add(
        UpdateSupplier(
          supplier.id,
          name: result['name'],
          contactInfo: result['contact_info'],
          isActive: result['is_active'],
        ),
      );
    }
  }

  Future<void> _openPayDebt(BuildContext ctx, Supplier supplier, String currency) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: ctx,
      builder: (_) => SupplierPaymentDialog(supplier: supplier, currency: currency),
    );
    if (result != null && ctx.mounted) {
      ctx.read<DocumentBloc>().add(
        RecordSupplierPayment(
          supplier.id,
          amount: result['amount'],
          paymentMethod: result['payment_method'] ?? 'cash',
          comment: result['comment'],
        ),
      );
    }
  }

  void _confirmDelete(BuildContext ctx, Supplier supplier) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AppDialog(
        title: 'Удалить поставщика?',
        icon: PhosphorIconsRegular.trash,
        isDestructive: true,
        width: 420,
        content: Text(
          'Поставщик «${supplier.name}» будет удалён.\nЕсли к нему привязаны накладные, история взаиморасчётов сохранится в архиве.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(ctx).brightness == Brightness.dark
                ? AppColors.darkSubtext
                : AppColors.lightSubtext,
          ),
        ),
        actions: [
          AppGhostButton(
            label: 'Отмена',
            onPressed: () => Navigator.pop(dCtx),
          ),
          AppDangerButton(
            label: 'Удалить',
            icon: PhosphorIconsRegular.trash,
            onPressed: () {
              Navigator.pop(dCtx);
              ctx.read<DocumentBloc>().add(DeleteSupplier(supplier.id));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = context.watch<SettingsBloc>().state.currency;

    return BlocConsumer<DocumentBloc, DocumentState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == DocumentStatus.loading && state.suppliers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: SkeletonList(),
          );
        }

        final int archivedCount = state.suppliers.where((s) => !s.isActive).length;
        final suppliers = state.suppliers.where((s) {
          if (_showArchived ? s.isActive : !s.isActive) return false;
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase().trim();
          return s.name.toLowerCase().contains(q) ||
              (s.contactInfo != null && s.contactInfo!.toLowerCase().contains(q)) ||
              s.id.toString().contains(q);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _showArchived ? 'Архив поставщиков' : 'Поставщики и взаиморасчеты',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${suppliers.length} записей',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      AppSearchField(
                        mode: AppSearchMode.collapsible,
                        size: AppSearchFieldSize.md,
                        hintText: 'Поиск поставщика...',
                        shortcutHint: 'Ctrl+F',
                        width: 240,
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                      const SizedBox(width: 8),
                      Badge(
                        isLabelVisible: archivedCount > 0,
                        label: Text('$archivedCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        child: AppSecondaryButton(
                          label: '',
                          icon: PhosphorIconsRegular.archive,
                          size: AppButtonSize.md,
                          isSelected: _showArchived,
                          tooltip: _showArchived ? 'Показать активных' : 'Архив поставщиков',
                          onPressed: () => setState(() => _showArchived = !_showArchived),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppPrimaryButton(
                        label: 'Добавить',
                        icon: PhosphorIconsRegular.plus,
                        size: AppButtonSize.md,
                        onPressed: () => _openCreate(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SuppliersTableHeader(),
            Expanded(
              child: suppliers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsRegular.truck,
                            size: 48,
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty ? 'Поставщики не найдены' : 'Нет поставщиков',
                            style: TextStyle(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: suppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = suppliers[index];
                        final isLast = index == suppliers.length - 1;
                        return SupplierRow(
                          supplier: supplier,
                          currency: currency,
                          isLast: isLast,
                          isDark: isDark,
                          onEdit: () => _openEdit(context, supplier),
                          onDelete: () => _confirmDelete(context, supplier),
                          onPayDebt: () => _openPayDebt(context, supplier, currency),
                          onOpenSettlement: () => SupplierSettlementDialog.show(context, supplier, currency),
                          onToggleActive: () {
                            context.read<DocumentBloc>().add(
                              UpdateSupplier(
                                supplier.id,
                                name: supplier.name,
                                contactInfo: supplier.contactInfo,
                                isActive: !supplier.isActive,
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
