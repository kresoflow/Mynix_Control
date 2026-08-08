import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'bloc/tenant_explorer_bloc.dart';
import 'widgets/data_grid_view.dart';

class TenantExplorerScreen extends StatefulWidget {
  final String tenantName;
  const TenantExplorerScreen({super.key, required this.tenantName});

  @override
  State<TenantExplorerScreen> createState() => _TenantExplorerScreenState();
}

class _TenantExplorerScreenState extends State<TenantExplorerScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TenantExplorerBloc>().loadTables();
  }

  void _showRowModal({Map<String, dynamic>? initialData}) {
    final state = context.read<TenantExplorerBloc>().state;
    if (state is! TenantExplorerLoaded || state.columns == null) return;

    final isEdit = initialData != null;
    final Map<String, dynamic> payload = initialData != null ? Map.from(initialData) : {};
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEdit ? 'Редактировать запись' : 'Создать запись', style: AppTextStyles.h2),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: state.columns!.map((c) {
                final colName = c['name'];
                final isPk = state.primaryKeys?.contains(colName) ?? false;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextFormField(
                    initialValue: payload[colName]?.toString(),
                    enabled: !(isEdit && isPk), // Cannot edit PK on update
                    decoration: InputDecoration(
                      labelText: colName + (isPk ? ' (PK)' : ''),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      if (val.isEmpty) {
                        payload[colName] = null;
                      } else {
                        payload[colName] = val; // Everything as string for now, backend will cast
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (isEdit) {
                  context.read<TenantExplorerBloc>().updateRow(payload);
                } else {
                  context.read<TenantExplorerBloc>().createRow(payload);
                }
              },
              child: Text(isEdit ? 'Сохранить' : 'Создать'),
            ),
          ],
        );
      }
    );
  }

  void _confirmDelete(Map<String, dynamic> row) {
    final state = context.read<TenantExplorerBloc>().state;
    if (state is! TenantExplorerLoaded || state.primaryKeys == null) return;

    final pkPayload = <String, dynamic>{};
    for (var pk in state.primaryKeys!) {
      pkPayload[pk] = row[pk];
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text('Удалить запись с ключами: $pkPayload? Это необратимо.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TenantExplorerBloc>().deleteRow(pkPayload);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text('Редактор данных: ${widget.tenantName}', style: AppTextStyles.h2),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 1,
      ),
      body: BlocBuilder<TenantExplorerBloc, TenantExplorerState>(
        builder: (context, state) {
          if (state is TenantExplorerLoading && state is! TenantExplorerLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TenantExplorerError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          }

          if (state is TenantExplorerLoaded) {
            return Row(
              children: [
                // Left Drawer - Tables
                Container(
                  width: 250,
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(PhosphorIcons.table(), color: AppColors.brandPrimary),
                            const SizedBox(width: 8),
                            Text('Таблицы', style: AppTextStyles.h3),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.tables.length,
                          itemBuilder: (context, index) {
                            final table = state.tables[index];
                            final isSelected = table == state.selectedTable;
                            return ListTile(
                              title: Text(table, style: AppTextStyles.bodyMedium.copyWith(
                                color: isSelected ? AppColors.brandPrimary : null,
                              )),
                              selected: isSelected,
                              selectedTileColor: AppColors.brandPrimary.withOpacity(0.1),
                              onTap: () {
                                context.read<TenantExplorerBloc>().loadTableData(table);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                
                // Right Content - Data Grid
                Expanded(
                  child: state.selectedTable == null 
                    ? const Center(child: Text('Выберите таблицу слева для просмотра данных'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Таблица: ${state.selectedTable}', style: AppTextStyles.h2),
                                ElevatedButton.icon(
                                  icon: Icon(PhosphorIcons.plus()),
                                  label: const Text('Добавить запись'),
                                  onPressed: () => _showRowModal(),
                                )
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: state.columns == null 
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
