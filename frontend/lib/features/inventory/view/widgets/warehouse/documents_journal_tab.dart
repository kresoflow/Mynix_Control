import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/skeleton_loader.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_event.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_state.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/blind_inventory_dialog.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document_dialog.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/write_off_document_dialog.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/document_detail/document_detail_dialog.dart';
import 'documents/document_journal_header.dart';
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
    final docBloc = context.read<DocumentBloc>();
    if (docBloc.state.documents.isEmpty) {
      docBloc.add(const LoadDocuments());
    }
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
                    size: AppButtonSize.md,
                    onPressed: () => _showReceiveDocumentDialog(context),
                  ),
                  const SizedBox(width: 8),
                  AppSecondaryButton(
                    label: 'Списание',
                    icon: PhosphorIconsRegular.trashSimple,
                    size: AppButtonSize.md,
                    onPressed: () => WriteOffDocumentDialog.show(context),
                  ),
                  const SizedBox(width: 8),
                  AppSecondaryButton(
                    label: 'Инвентаризация',
                    icon: PhosphorIconsRegular.clipboardText,
                    size: AppButtonSize.md,
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
                borderRadius: AppRadii.cardRadius,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: ClipRRect(
                borderRadius: AppRadii.cardRadius,
                child: Column(
                  children: [
                    // Table Header
                    const DocumentJournalHeader(),

                    // Table Body
                    Expanded(
                      child: BlocBuilder<DocumentBloc, DocumentState>(
                        builder: (context, state) {
                          if ((state.status == DocumentStatus.initial ||
                                  state.status == DocumentStatus.loading) &&
                              state.documents.isEmpty) {
                            return const SkeletonList();
                          }
                          if (state.status == DocumentStatus.failure && state.documents.isEmpty) {
                            return Center(
                              child: Text(
                                'Ошибка загрузки: ${state.errorMessage}',
                                style: AppTextStyles.caption.copyWith(color: AppColors.danger),
                              ),
                            );
                          }

                          final docs = state.documents.where((d) {
                            if (_selectedFilter != 'all' && d.type != _selectedFilter) return false;
                            if (_searchQuery.isEmpty) return true;
                            final q = _searchQuery.toLowerCase().trim();
                            return d.id.toString().contains(q) ||
                                (d.supplierName != null && d.supplierName!.toLowerCase().contains(q)) ||
                                (d.reason != null && d.reason!.toLowerCase().contains(q)) ||
                                (d.invoiceNumber != null && d.invoiceNumber!.toLowerCase().contains(q));
                          }).toList();

                          if (docs.isEmpty) {
                            final isFiltered = _searchQuery.isNotEmpty || _selectedFilter != 'all';
                            return Center(
                              child: AppEmptyState(
                                icon: PhosphorIconsRegular.receipt,
                                title: isFiltered ? 'Документы не найдены' : 'Журнал документов пуст',
                                description: isFiltered
                                    ? 'Попробуйте изменить параметры поиска или сбросить фильтрацию'
                                    : 'Оформите первый приход, списание или инвентаризацию',
                                size: AppEmptyStateSize.md,
                                action: isFiltered
                                    ? AppSecondaryButton(
                                        label: 'Сбросить фильтры',
                                        icon: PhosphorIconsRegular.arrowCounterClockwise,
                                        size: AppButtonSize.sm,
                                        onPressed: () {
                                          setState(() {
                                            _searchQuery = '';
                                            _selectedFilter = 'all';
                                          });
                                        },
                                      )
                                    : AppPrimaryButton(
                                        label: 'Оформить приход',
                                        icon: PhosphorIconsRegular.truck,
                                        size: AppButtonSize.md,
                                        onPressed: () => _showReceiveDocumentDialog(context),
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