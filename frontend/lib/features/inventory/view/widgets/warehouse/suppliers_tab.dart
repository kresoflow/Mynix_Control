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

class _SuppliersTabState extends State<SuppliersTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _searchQuery = '';
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    final docBloc = context.read<DocumentBloc>();
    if (docBloc.state.suppliers.isEmpty) {
      docBloc.add(const LoadSuppliers());
    }
  }

  Future<void> _openCreate(BuildContext context) async {
    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreateSupplierDialog(),
    );
    if (res != null && context.mounted) {
      context.read<DocumentBloc>().add(
        CreateSupplier(
          res['name'],
          contactInfo: res['contact_info'],
          initialBalance: double.tryParse(res['initial_balance']?.toString() ?? ''),
        ),
      );
    }
  }

  Future<void> _openEdit(BuildContext ctx, Supplier supplier) async {
    final res = await showDialog<Map<String, dynamic>>(
      context: ctx,
      builder: (_) => EditSupplierDialog(supplier: supplier),
    );
    if (res != null && ctx.mounted) {
      ctx.read<DocumentBloc>().add(
        UpdateSupplier(
          supplier.id,
          name: res['name'],
          contactInfo: res['contact_info'],
          isActive: res['is_active'],
        ),
      );
    }
  }

  Future<void> _openPayDebt(BuildContext ctx, Supplier supplier, String currency) async {
    final res = await showDialog<Map<String, dynamic>>(
      context: ctx,
      builder: (_) => SupplierPaymentDialog(supplier: supplier, currency: currency),
    );
    if (res != null && ctx.mounted) {
      ctx.read<DocumentBloc>().add(
        RecordSupplierPayment(
          supplier.id,
          amount: res['amount'],
          paymentMethod: res['payment_method'] ?? 'cash',
          comment: res['comment'],
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext ctx, Supplier supplier) async {
    final confirmed = await AppConfirmDialog.show(
      context: ctx,
      title: 'Удалить поставщика?',
      message: 'Поставщик «${supplier.name}» будет удалён.\nИстория взаиморасчётов сохранится в архиве.',
      confirmLabel: 'Удалить',
      isDanger: true,
      icon: PhosphorIconsRegular.trash,
    );
    if (confirmed == true && ctx.mounted) {
      ctx.read<DocumentBloc>().add(DeleteSupplier(supplier.id));
    }
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchQuery.isNotEmpty;
    return Center(
      child: AppEmptyState(
        icon: PhosphorIconsRegular.truck,
        title: hasSearch ? 'Поставщики не найдены' : (_showArchived ? 'Архив поставщиков пуст' : 'Нет поставщиков'),
        description: hasSearch
            ? 'Проверьте правильность написания или сбросьте поиск'
            : (_showArchived
                ? 'В архиве пока нет скрытых контрагентов'
                : 'Добавьте первого контрагента для учета поставок и взаиморасчетов'),
        size: AppEmptyStateSize.md,
        action: hasSearch
            ? AppSecondaryButton(
                label: 'Сбросить поиск',
                icon: PhosphorIconsRegular.arrowCounterClockwise,
                size: AppButtonSize.sm,
                onPressed: () => setState(() => _searchQuery = ''),
              )
            : (!_showArchived
                ? AppPrimaryButton(
                    label: 'Добавить поставщика',
                    icon: PhosphorIconsRegular.plus,
                    size: AppButtonSize.md,
                    onPressed: () => _openCreate(context),
                  )
                : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.inputRadius),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.suppliersStatus == DocumentStatus.loading && state.suppliers.isEmpty) {
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

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _showArchived ? 'Архив поставщиков' : 'Поставщики и взаиморасчеты',
                        style: AppTextStyles.h2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${suppliers.length} записей',
                        style: AppTextStyles.caption.copyWith(
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
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: AppRadii.cardRadius,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadii.cardRadius,
                    child: Column(
                      children: [
                        const SuppliersTableHeader(),
                        Expanded(
                          child: suppliers.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  itemCount: suppliers.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  ),
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
