import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/skeleton_loader.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_state.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/dialogs/blind_inventory_dialog.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document_dialog.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/dialogs/document_detail/document_detail_dialog.dart';
import 'documents/document_journal_row.dart';
import 'documents/documents_toolbar.dart';

class DocumentsJournalTab extends StatefulWidget {
  const DocumentsJournalTab({super.key});

  @override
  State<DocumentsJournalTab> createState() => _DocumentsJournalTabState();
}

class _DocumentsJournalTabState extends State<DocumentsJournalTab> {
  String _selectedFilter = 'all';

  void _showReceiveDocumentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<DocumentBloc>(),
        child: const ReceiveDocumentDialog(),
      ),
    );
  }

  void _showWriteOffNotice(BuildContext context) {
    AppToast.showInfo(
      context,
      'Раздел списания',
      subtitle: 'Массовое списание находится в разработке.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DocumentsToolbar(
          selectedFilter: _selectedFilter,
          onFilterChanged: (val) {
            setState(() => _selectedFilter = val);
            context.read<DocumentBloc>().add(
                  LoadDocuments(type: _selectedFilter == 'all' ? null : _selectedFilter),
                );
          },
          onReceiveDocument: () => _showReceiveDocumentDialog(context),
          onWriteOff: () => _showWriteOffNotice(context),
          onBlindInventory: () => BlindInventoryDialog.show(context),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
              const SizedBox(width: 50),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<DocumentBloc, DocumentState>(
            builder: (context, state) {
              if (state.status == DocumentStatus.initial ||
                  state.status == DocumentStatus.loading) {
                return const SkeletonList();
              }
              if (state.status == DocumentStatus.failure) {
                return Center(
                  child: Text('Ошибка загрузки: ${state.errorMessage}',
                      style: const TextStyle(color: AppColors.danger)),
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
                  return DocumentJournalRow(
                    doc: doc,
                    onTap: () => DocumentDetailDialog.show(context, doc.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}