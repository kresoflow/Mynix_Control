import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/skeleton_loader.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_state.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/dialogs/blind_inventory_dialog.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document_dialog.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/dialogs/write_off_document_dialog.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/dialogs/document_detail/document_detail_dialog.dart';
import 'documents/document_journal_row.dart';
import 'documents/documents_toolbar.dart';

class DocumentsJournalTab extends StatefulWidget {
  const DocumentsJournalTab({super.key});

  @override
  State<DocumentsJournalTab> createState() => _DocumentsJournalTabState();
}

class _DocumentsJournalTabState extends State<DocumentsJournalTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<DocumentBloc>().add(const LoadDocuments());
  }

  void _showReceiveDocumentDialog(BuildContext context) {
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
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Line: Title on Left, Action Buttons on Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Журнал складских документов',
                style: AppTextStyles.h2,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppPrimaryButton(
                    label: 'Оформить приход',
                    icon: PhosphorIconsRegular.truck,
                    onPressed: () => _showReceiveDocumentDialog(context),
                  ),
                  const SizedBox(width: 8),
                  AppSecondaryButton(
                    label: 'Списание',
                    icon: PhosphorIconsRegular.trashSimple,
                    onPressed: () => WriteOffDocumentDialog.show(context),
                  ),
                  const SizedBox(width: 8),
                  AppSecondaryButton(
                    label: 'Инвентаризация',
                    icon: PhosphorIconsRegular.clipboardText,
                    onPressed: () => BlindInventoryDialog.show(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sub Toolbar (Filter Pills + Search Bar)
          DocumentsToolbar(
            selectedFilter: _selectedFilter,
            onFilterChanged: (val) {
              setState(() => _selectedFilter = val);
              context.read<DocumentBloc>().add(
                    LoadDocuments(type: _selectedFilter == 'all' ? null : _selectedFilter),
                  );
            },
            searchQuery: _searchQuery,
            onSearchChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 16),

          // Document Table Card Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161B26) : const Color(0xFFF1F5F9),
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              'ID',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'ДАТА',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'ТИП',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'ПОСТАВЩИК / КОММЕНТАРИЙ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'СУММА',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'СТАТУС',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),

                    // Table Body
                    Expanded(
                      child: BlocBuilder<DocumentBloc, DocumentState>(
                        builder: (context, state) {
                          if (state.status == DocumentStatus.initial ||
                              state.status == DocumentStatus.loading) {
                            return const SkeletonList();
                          }
                          if (state.status == DocumentStatus.failure) {
                            return Center(
                              child: Text(
                                'Ошибка загрузки: ${state.errorMessage}',
                                style: const TextStyle(color: AppColors.danger),
                              ),
                            );
                          }

                          final docs = state.documents.where((d) {
                            if (_searchQuery.isEmpty) return true;
                            final q = _searchQuery.toLowerCase().trim();
                            return d.id.toString().contains(q) ||
                                (d.supplierName != null && d.supplierName!.toLowerCase().contains(q)) ||
                                (d.reason != null && d.reason!.toLowerCase().contains(q)) ||
                                (d.invoiceNumber != null && d.invoiceNumber!.toLowerCase().contains(q));
                          }).toList();

                          if (docs.isEmpty) {
                            return Center(
                              child: Text(
                                'Документы не найдены',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: docs.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                            itemBuilder: (context, index) {
                              final doc = docs[index];
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}