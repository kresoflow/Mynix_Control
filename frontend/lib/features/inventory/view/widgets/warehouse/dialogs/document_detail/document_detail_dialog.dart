import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_event.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document_dialog.dart';
import 'document_detail_header.dart';
import 'document_detail_payment_info.dart';
import 'document_detail_items_table.dart';
import 'document_detail_footer.dart';

class DocumentDetailDialog extends StatefulWidget {
  final int documentId;

  const DocumentDetailDialog({super.key, required this.documentId});

  static Future<void> show(BuildContext context, int documentId) {
    final docBloc = context.read<DocumentBloc>();
    return showDialog(
      context: context,
      builder: (_) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: context.read<InventoryRepository>()),
        ],
        child: BlocProvider.value(
          value: docBloc,
          child: DocumentDetailDialog(documentId: documentId),
        ),
      ),
    );
  }

  @override
  State<DocumentDetailDialog> createState() => _DocumentDetailDialogState();
}

class _DocumentDetailDialogState extends State<DocumentDetailDialog> {
  late Future<InventoryDocument> _documentFuture;

  @override
  void initState() {
    super.initState();
    _documentFuture = context.read<InventoryRepository>().getDocument(widget.documentId);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _completeDraft(InventoryDocument doc) {
    context.read<DocumentBloc>().add(CompleteDocument(doc.id));
    _showSnack('Накладная #${doc.id} проводится...');
    Navigator.of(context).pop();
  }

  void _editDraft(InventoryDocument doc) {
    final docBloc = context.read<DocumentBloc>();
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: docBloc,
        child: ReceiveDocumentDialog(initialDocument: doc),
      ),
    );
  }

  Future<void> _deleteDraft(InventoryDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить черновик?'),
        content: Text('Черновик накладной #${doc.id} будет безвозвратно удален.'),
        actions: [
          AppButton.secondary(
            label: 'Отмена',
            height: 36,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppButton.danger(
            label: 'Удалить',
            height: 36,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<DocumentBloc>().add(DeleteDocument(doc.id));
      _showSnack('Черновик #${doc.id} удален');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const currency = 'с';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          width: 700,
          constraints: const BoxConstraints(maxHeight: 800),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: FutureBuilder<InventoryDocument>(
            future: _documentFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsRegular.warningCircle, color: AppColors.danger, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Не удалось загрузить документ',
                        style: AppTextStyles.h3.copyWith(color: AppColors.danger),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error?.toString() ?? 'Неизвестная ошибка',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 24),
                      AppButton.secondary(
                        label: 'Закрыть',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
              }

              final doc = snapshot.data!;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DocumentDetailHeader(doc: doc),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DocumentDetailPaymentInfo(doc: doc),
                          DocumentDetailItemsTable(doc: doc),
                        ],
                      ),
                    ),
                  ),
                  DocumentDetailFooter(
                    doc: doc,
                    currency: currency,
                    onSnack: _showSnack,
                    onCompleteDraft: () => _completeDraft(doc),
                    onEditDraft: () => _editDraft(doc),
                    onDeleteDraft: () => _deleteDraft(doc),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
