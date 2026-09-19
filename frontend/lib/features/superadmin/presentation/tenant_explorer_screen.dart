import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_nav_tile.dart';
import 'bloc/tenant_explorer_bloc.dart';
import 'widgets/data_grid_view.dart';

class TenantExplorerScreen extends StatefulWidget {
  final String tenantName;
  const TenantExplorerScreen({super.key, required this.tenantName});

  @override
  State<TenantExplorerScreen> createState() => _TenantExplorerScreenState();
}

class _TenantExplorerScreenState extends State<TenantExplorerScreen> {
  bool _isSidebarExpanded = true;
  final TextEditingController _tableSearchController = TextEditingController();
  String _tableSearchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<TenantExplorerBloc>().loadTables();
    _tableSearchController.addListener(() {
      setState(() => _tableSearchQuery = _tableSearchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tableSearchController.dispose();
    super.dispose();
  }

  static const _meta = <String, (String, IconData)>{
    'menu_items': ('Блюда и меню', PhosphorIconsRegular.hamburger), 'menu_categories': ('Категории блюд', PhosphorIconsRegular.folderSimple),
    'ingredients': ('Ингредиенты', PhosphorIconsRegular.package), 'inventory_documents': ('Накладные склада', PhosphorIconsRegular.fileText),
    'inventory_document_items': ('Позиции накладных', PhosphorIconsRegular.listNumbers), 'suppliers': ('Поставщики', PhosphorIconsRegular.truck),
    'supplier_transactions': ('Расчеты с поставщиками', PhosphorIconsRegular.receipt), 'orders': ('Заказы', PhosphorIconsRegular.receipt),
    'order_items': ('Позиции заказов', PhosphorIconsRegular.listDashes), 'shifts': ('Кассовые смены', PhosphorIconsRegular.clock),
    'customers': ('Клиенты (CRM)', PhosphorIconsRegular.users), 'customer_transactions': ('Оплаты клиентов', PhosphorIconsRegular.creditCard),
    'bonus_transactions': ('Бонусные баллы', PhosphorIconsRegular.gift), 'recipes': ('Техкарты', PhosphorIconsRegular.cookingPot),
    'stock_transactions': ('Движения склада', PhosphorIconsRegular.arrowsLeftRight), 'cash_transactions': ('Движения кассы', PhosphorIconsRegular.money),
    'retail_products': ('Штучные товары', PhosphorIconsRegular.tag),
  };

  (String, IconData) _getTableMeta(String t) => _meta[t] ?? (t, PhosphorIconsRegular.table);

  void _showRowModal({Map<String, dynamic>? initialData}) {
    final state = context.read<TenantExplorerBloc>().state;
    if (state is! TenantExplorerLoaded || state.columns == null) return;

    final isEdit = initialData != null;
    final Map<String, dynamic> payload = initialData != null ? Map.from(initialData) : {};

    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: isEdit ? 'Редактировать запись' : 'Создать запись',
        icon: isEdit ? PhosphorIconsRegular.pencilSimple : PhosphorIconsRegular.plusCircle,
        width: 520,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 450),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: state.columns!.map((c) {
                final colName = c['name'] as String;
                final isPk = state.primaryKeys?.contains(colName) ?? false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: TextFormField(
                    initialValue: payload[colName]?.toString(),
                    enabled: !(isEdit && isPk),
                    decoration: InputDecoration(labelText: colName + (isPk ? ' (PK)' : ''), border: const OutlineInputBorder()),
                    onChanged: (val) => payload[colName] = val.isEmpty ? null : val,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          AppSecondaryButton(label: 'Отмена', size: AppButtonSize.md, onPressed: () => Navigator.pop(ctx)),
          const SizedBox(width: 8),
          AppPrimaryButton(
            label: isEdit ? 'Сохранить' : 'Создать',
            size: AppButtonSize.md,
            onPressed: () {
              Navigator.pop(ctx);
              isEdit ? context.read<TenantExplorerBloc>().updateRow(payload) : context.read<TenantExplorerBloc>().createRow(payload);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> row) {
    final state = context.read<TenantExplorerBloc>().state;
    if (state is! TenantExplorerLoaded || state.primaryKeys == null) return;
    final pkPayload = {for (var pk in state.primaryKeys!) pk: row[pk]};

    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Удалить запись?',
        icon: PhosphorIconsRegular.warningCircle,
        isDestructive: true,
        content: Text('Удалить запись с ключами: $pkPayload? Это действие необратимо.', style: AppTextStyles.bodyMedium),
        actions: [
          AppSecondaryButton(label: 'Отмена', size: AppButtonSize.md, onPressed: () => Navigator.pop(ctx)),
          const SizedBox(width: 8),
          AppDangerButton(
            label: 'Удалить',
            size: AppButtonSize.md,
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TenantExplorerBloc>().deleteRow(pkPayload);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              icon: Icon(_isSidebarExpanded ? PhosphorIconsRegular.sidebarSimple : PhosphorIconsRegular.list),
              tooltip: _isSidebarExpanded ? 'Скрыть список таблиц' : 'Показать таблицы',
              onPressed: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
            ),
            const SizedBox(width: 8),
            Text(
              'Инспектор БД: ${widget.tenantName}',
              style: AppTextStyles.h2.copyWith(color: isDark ? AppColors.darkText : AppColors.lightText),
            ),
          ],
        ),
        foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
        iconTheme: IconThemeData(color: isDark ? AppColors.darkText : AppColors.lightText),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 1,
      ),
      body: BlocBuilder<TenantExplorerBloc, TenantExplorerState>(
        builder: (context, state) {
          if (state is TenantExplorerLoading && state is! TenantExplorerLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TenantExplorerError) {
            return Center(
              child: Text(state.message, style: AppTextStyles.caption.copyWith(color: AppColors.danger)),
            );
          }

          if (state is TenantExplorerLoaded) {
            final selectedMeta = state.selectedTable != null ? _getTableMeta(state.selectedTable!) : null;
            final visibleTables = _tableSearchQuery.isEmpty
                ? state.tables
                : state.tables
                    .where((t) => t.toLowerCase().contains(_tableSearchQuery) || _getTableMeta(t).$1.toLowerCase().contains(_tableSearchQuery))
                    .toList();

            return Row(
              children: [
                if (_isSidebarExpanded) ...[
                  // Left Drawer - Tables
                  Container(
                    width: 270,
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(PhosphorIconsRegular.database, color: AppColors.brandPrimary, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Таблицы', style: AppTextStyles.h3.copyWith(color: isDark ? AppColors.darkText : AppColors.lightText)),
                                  const Spacer(),
                                  Text('${visibleTables.length}', style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 32,
                                child: TextField(
                                  controller: _tableSearchController,
                                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                                  decoration: InputDecoration(
                                    hintText: 'Поиск таблицы...',
                                    hintStyle: AppTextStyles.caption.copyWith(fontSize: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                                    prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 14),
                                    filled: true,
                                    fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            itemCount: visibleTables.length,
                            itemBuilder: (context, index) {
                              final table = visibleTables[index];
                              final isSelected = table == state.selectedTable;
                              final meta = _getTableMeta(table);

                              return AppNavTile(
                                title: meta.$1,
                                subtitle: table,
                                icon: meta.$2,
                                isSelected: isSelected,
                                size: AppNavTileSize.md,
                                onTap: () => context.read<TenantExplorerBloc>().loadTableData(table),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                ],

                // Right Content - Data Grid
                Expanded(
                  child: state.selectedTable == null
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (selectedMeta != null) ...[Icon(selectedMeta.$2, size: 20, color: AppColors.brandPrimary), const SizedBox(width: 8)],
                                          Text(selectedMeta?.$1 ?? 'Таблица', style: AppTextStyles.h2.copyWith(color: isDark ? AppColors.darkText : AppColors.lightText)),
                                        ],
                                      ),
                                      Text('Таблица: ${state.selectedTable}', style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                                    ],
                                  ),
                                  AppPrimaryButton(icon: PhosphorIconsRegular.plus, label: 'Добавить запись', size: AppButtonSize.md, onPressed: () => _showRowModal()),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: state.isTableLoading || state.columns == null
                                  ? const Center(child: CircularProgressIndicator())
                                  : DataGridView(
                                      columns: state.columns!,
                                      rows: state.rows ?? [],
                                      primaryKeys: state.primaryKeys ?? [],
                                      onEdit: (row) => _showRowModal(initialData: row),
                                      onDelete: (row) => _confirmDelete(row),
                                    ),
                            ),
                          ],
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
