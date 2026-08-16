import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_state.dart';
import 'package:mynix_frontend/features/inventory/models/supplier.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/dialogs/create_supplier_dialog.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/dialogs/edit_supplier_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/widgets/skeleton_loader.dart';
import 'supplier_row.dart';

export 'supplier_row.dart';

class SuppliersTab extends StatefulWidget {
  const SuppliersTab({super.key});

  @override
  State<SuppliersTab> createState() => _SuppliersTabState();
}

class _SuppliersTabState extends State<SuppliersTab> {
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
    if (result != null && mounted) {
      context.read<DocumentBloc>().add(
        CreateSupplier(result['name'], contactInfo: result['contact_info']),
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

  void _confirmDelete(BuildContext ctx, Supplier supplier) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить поставщика?'),
        content: Text(
          'Поставщик «${supplier.name}» будет удалён.\n'
          'Если к нему привязаны накладные — система предложит деактивацию.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dCtx);
              ctx.read<DocumentBloc>().add(DeleteSupplier(supplier.id));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<DocumentBloc, DocumentState>(
      builder: (ctx, state) {
        if (state.status == DocumentStatus.loading && state.suppliers.isEmpty) {
          return const SkeletonList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Поставщики',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      Text(
                        '${state.suppliers.length} записей',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _openCreate(context),
                    icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                    label: const Text('Добавить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : AppColors.lightBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        'ID',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Название',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Контактные данные',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 90,
                      child: Text('Статус', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                    const SizedBox(width: 80),
                  ],
                ),
              ),
            ),
            Expanded(
              child: state.suppliers.isEmpty
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
                            'Нет поставщиков',
                            style: TextStyle(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: state.suppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = state.suppliers[index];
                        final isLast = index == state.suppliers.length - 1;
                        return SupplierRow(
                          supplier: supplier,
                          isLast: isLast,
                          isDark: isDark,
                          onEdit: () => _openEdit(context, supplier),
                          onDelete: () => _confirmDelete(context, supplier),
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
