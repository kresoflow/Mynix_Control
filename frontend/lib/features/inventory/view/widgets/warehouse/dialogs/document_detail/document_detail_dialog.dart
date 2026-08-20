import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/inventory/models/document.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'document_detail_header.dart';
import 'document_detail_payment_info.dart';
import 'document_detail_items_table.dart';
import 'document_detail_footer.dart';

class DocumentDetailDialog extends StatefulWidget {
  final int documentId;

  const DocumentDetailDialog({super.key, required this.documentId});

  static Future<void> show(BuildContext context, int documentId) {
    return showDialog(
      context: context,
      builder: (_) => RepositoryProvider.value(
        value: context.read<InventoryRepository>(),
        child: DocumentDetailDialog(documentId: documentId),
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
          width: 640,
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
