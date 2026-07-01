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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // ── Toolbar ──────────────────────────────────────────────────
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

            // ── Table Header ──────────────────────────────────────────────
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
                      child: Text('ID',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12,
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Название',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12,
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('Контактные данные',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12,
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                    ),
                    const SizedBox(
                      width: 90,
                      child: Text('Статус',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                    const SizedBox(width: 80),
                  ],
                ),
              ),
            ),

            // ── Table Body ────────────────────────────────────────────────
            Expanded(
              child: state.suppliers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.truck,
                              size: 48,
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                          const SizedBox(height: 12),
                          Text('Нет поставщиков',
                              style: TextStyle(
                                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: state.suppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = state.suppliers[index];
                        final isLast = index == state.suppliers.length - 1;
                        return _SupplierRow(
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

// ── Строка поставщика с Hover ──────────────────────────────────────────────
class _SupplierRow extends StatefulWidget {
  final Supplier supplier;
  final bool isLast;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _SupplierRow({
    required this.supplier,
    required this.isLast,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  State<_SupplierRow> createState() => _SupplierRowState();
}

class _SupplierRowState extends State<_SupplierRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.supplier;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovered
              ? (widget.isDark
                  ? AppColors.darkBg.withValues(alpha: 0.6)
                  : AppColors.brandPrimary.withValues(alpha: 0.03))
              : (widget.isDark ? AppColors.darkSurface : AppColors.lightSurface),
          border: Border(
            left: BorderSide(color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
            right: BorderSide(color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
            bottom: BorderSide(color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          borderRadius: widget.isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(12))
              : BorderRadius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // ID
              SizedBox(
                width: 44,
                child: Text(
                  '#${s.id}',
                  style: TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              // Название
              Expanded(
                flex: 2,
                child: Text(
                  s.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: widget.isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ),
              // Контакт
              Expanded(
                flex: 3,
                child: Text(
                  s.contactInfo ?? '—',
                  style: TextStyle(
                    color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Статус
              SizedBox(
                width: 90,
                child: GestureDetector(
                  onTap: widget.onToggleActive,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: s.isActive
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.red.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.isActive ? 'Активен' : 'Неактивен',
                      style: TextStyle(
                        color: s.isActive ? Colors.green : Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              // Действия
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: SizedBox(
                  width: 80,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(PhosphorIconsRegular.pencilSimple,
                            color: AppColors.brandTertiary, size: 16),
                        onPressed: widget.onEdit,
                        tooltip: 'Редактировать',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        splashRadius: 16,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(PhosphorIconsRegular.trash,
                            color: Colors.redAccent, size: 16),
                        onPressed: widget.onDelete,
                        tooltip: 'Удалить / Деактивировать',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        splashRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
