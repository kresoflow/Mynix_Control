import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_state.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document_dialog.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/dialogs/blind_inventory_dialog.dart';

import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
class DocumentsJournalTab extends StatefulWidget {
  const DocumentsJournalTab({super.key});

  @override
  State<DocumentsJournalTab> createState() => _DocumentsJournalTabState();
}

class _DocumentsJournalTabState extends State<DocumentsJournalTab> {
  String _selectedFilter = 'all'; // all, receipt, write_off, inventory

  @override
  void initState() {
    super.initState();
    // Wrap in Builder or make sure Bloc is provided above this widget
  }

  Color _getStatusColor(String status) {
    if (status == 'completed') return Colors.green;
    if (status == 'draft') return Colors.orange;
    if (status == 'cancelled') return Colors.red;
    return Colors.grey;
  }

  String _getStatusLabel(String status) {
    if (status == 'completed') return 'Проведен';
    if (status == 'draft') return 'Черновик';
    if (status == 'cancelled') return 'Отменен';
    return status;
  }

  String _getTypeLabel(String type) {
    if (type == 'receipt') return 'Приход';
    if (type == 'write_off') return 'Списание';
    if (type == 'inventory') return 'Инвентаризация';
    return type;
  }

  Color _getTypeColor(String type) {
    if (type == 'receipt') return Colors.blue;
    if (type == 'write_off') return Colors.deepOrange;
    if (type == 'inventory') return Colors.purple;
    return Colors.grey;
  }

  void _showReceiveDocumentDialog(BuildContext context) {
    // Show wide modal
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<DocumentBloc>(),
        child: const ReceiveDocumentDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Wrap(
                spacing: 8.0,
                children: [
                  _buildPill(context, 'Все', 'all'),
                  _buildPill(context, 'Приходы', 'receipt'),
                  _buildPill(context, 'Списания', 'write_off'),
                  _buildPill(context, 'Инвентаризации', 'inventory'),
                ],
              ),
              const Spacer(),
              AppPrimaryButton(
                label: 'Оформить приход',
                icon: PhosphorIconsRegular.truck,
                onPressed: () => _showReceiveDocumentDialog(context),
              ),
              const SizedBox(width: 8),
              AppGhostButton(
                label: 'Списание',
                icon: PhosphorIconsRegular.shoppingCart,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Раздел массового списания находится в разработке.'),
                      backgroundColor: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF161B22) 
                          : Colors.black87,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              AppGhostButton(
                label: 'Инвентаризация',
                icon: PhosphorIconsRegular.clipboardText,
                onPressed: () => BlindInventoryDialog.show(context),
              ),
            ],
          ),
        ),
        
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              SizedBox(width: 50, child: Text('ID', style: AppTextStyles.h3)),
              Expanded(flex: 2, child: Text('Дата', style: AppTextStyles.h3)),
              Expanded(flex: 2, child: Text('Тип', style: AppTextStyles.h3)),
              Expanded(flex: 3, child: Text('Поставщик / Комментарий', style: AppTextStyles.h3)),
              Expanded(flex: 2, child: Text('Сумма', style: AppTextStyles.h3)),
              Expanded(flex: 2, child: Text('Статус', style: AppTextStyles.h3)),
              SizedBox(width: 50), // Actions
            ],
          ),
        ),

        // List
        Expanded(
          child: BlocBuilder<DocumentBloc, DocumentState>(
            builder: (context, state) {
              if (state.status == DocumentStatus.initial ||
                  state.status == DocumentStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == DocumentStatus.failure) {
                return Center(
                  child: Text('Ошибка загрузки: ${state.errorMessage}',
                      style: const TextStyle(color: Colors.red)),
                );
              }
              if (state.documents.isEmpty) {
                return const Center(child: Text('Нет документов'));
              }

              return ListView.separated(
                itemCount: state.documents.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = state.documents[index];
                  return InkWell(
                    onTap: () {
                      // Open details
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(width: 50, child: Text('#${doc.id}')),
                          Expanded(
                            flex: 2,
                            child: Text(DateFormat('dd.MM.yyyy HH:mm').format(doc.date.toLocal())),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getTypeColor(doc.type).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getTypeLabel(doc.type),
                                  style: TextStyle(
                                    color: _getTypeColor(doc.type),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              doc.type == 'receipt'
                                  ? (doc.supplierName ?? 'Неизвестный поставщик')
                                  : (doc.reason ?? '-'),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              doc.totalAmount.toCurrency(context),
                              style: AppTextStyles.h3,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(doc.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getStatusLabel(doc.status),
                                  style: TextStyle(
                                    color: _getStatusColor(doc.status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 50,
                            child: Icon(PhosphorIconsRegular.caretRight, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPill(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        context.read<DocumentBloc>().add(
              LoadDocuments(
                type: _selectedFilter == 'all' ? null : _selectedFilter,
              ),
            );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBg : AppColors.lightBg),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.brandPrimary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}