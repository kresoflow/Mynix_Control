import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/inventory/models/document.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:mynix_frontend/features/inventory/services/document_export_service.dart';
import 'document_detail_header.dart';
import 'document_detail_payment_info.dart';
import 'document_detail_items_table.dart';

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
    final currency = 'с';

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
                  // 1. Header (No borders)
                  DocumentDetailHeader(doc: doc),

                  // 2. Scrollable Body
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

                  // 3. Footer Action Bar (No border)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        AppButton.ghost(
                          label: 'Закрыть',
                          icon: PhosphorIconsRegular.x,
                          height: 38,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),

                        // Меню других форматов экспорта
                        PopupMenuButton<String>(
                          tooltip: 'Другие форматы экспорта',
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (action) async {
                            switch (action) {
                              case 'excel':
                                DocumentExportService.exportExcel(doc, currency);
                                _showSnack('Таблица Excel (.csv) скачана');
                                break;
                              case 'txt':
                                DocumentExportService.exportTxt(doc, currency);
                                _showSnack('Файл TXT скачан');
                                break;
                              case 'copy_text':
                                await DocumentExportService.copyAsText(doc, currency);
                                _showSnack('Чек скопирован в буфер для WhatsApp/Telegram');
                                break;
                              case 'json':
                                DocumentExportService.exportJson(doc);
                                _showSnack('Файл JSON скачан');
                                break;
                              case 'copy_json':
                                await DocumentExportService.copyAsJson(doc);
                                _showSnack('JSON скопирован в буфер обмена');
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'excel',
                              child: Row(
                                children: [
                                  Icon(PhosphorIconsRegular.fileXls, size: 18, color: AppColors.success),
                                  SizedBox(width: 10),
                                  Text('Экспорт в Excel (.csv)'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'txt',
                              child: Row(
                                children: [
                                  Icon(PhosphorIconsRegular.fileText, size: 18, color: AppColors.info),
                                  SizedBox(width: 10),
                                  Text('Скачать как TXT'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'copy_text',
                              child: Row(
                                children: [
                                  Icon(PhosphorIconsRegular.whatsappLogo, size: 18, color: AppColors.success),
                                  SizedBox(width: 10),
                                  Text('Скопировать для WhatsApp'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'json',
                              child: Row(
                                children: [
                                  Icon(PhosphorIconsRegular.code, size: 18, color: AppColors.warning),
                                  SizedBox(width: 10),
                                  Text('Скачать JSON'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'copy_json',
                              child: Row(
                                children: [
                                  Icon(PhosphorIconsRegular.copy, size: 18, color: Colors.grey),
                                  SizedBox(width: 10),
                                  Text('Копировать JSON'),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(PhosphorIconsRegular.export, size: 16),
                                SizedBox(width: 6),
                                Text('Экспорт', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                SizedBox(width: 4),
                                Icon(PhosphorIconsRegular.caretDown, size: 12),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Кнопка: Печать
                        AppButton.secondary(
                          label: 'Печать',
                          icon: PhosphorIconsRegular.printer,
                          height: 38,
                          onPressed: () async {
                            await DocumentExportService.printDocument(doc, currency);
                          },
                        ),
                        const SizedBox(width: 8),

                        // Главная кнопка: Скачать PDF
                        AppButton.primary(
                          label: 'Скачать PDF',
                          icon: PhosphorIconsRegular.filePdf,
                          height: 38,
                          onPressed: () async {
                            _showSnack('Генерация и скачивание PDF...');
                            await DocumentExportService.downloadPdf(doc, currency);
                            _showSnack('Файл PDF скачан');
                          },
                        ),
                      ],
                    ),
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
