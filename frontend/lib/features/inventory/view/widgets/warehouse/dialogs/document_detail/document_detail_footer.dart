import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/inventory/models/document.dart';
import 'package:mynix_frontend/features/inventory/services/document_export_service.dart';

class DocumentDetailFooter extends StatelessWidget {
  final InventoryDocument doc;
  final String currency;
  final ValueChanged<String> onSnack;

  const DocumentDetailFooter({
    super.key,
    required this.doc,
    required this.currency,
    required this.onSnack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
                  onSnack('Таблица Excel (.csv) скачана');
                  break;
                case 'txt':
                  DocumentExportService.exportTxt(doc, currency);
                  onSnack('Файл TXT скачан');
                  break;
                case 'copy_text':
                  await DocumentExportService.copyAsText(doc, currency);
                  onSnack('Чек скопирован в буфер для WhatsApp/Telegram');
                  break;
                case 'json':
                  DocumentExportService.exportJson(doc);
                  onSnack('Файл JSON скачан');
                  break;
                case 'copy_json':
                  await DocumentExportService.copyAsJson(doc);
                  onSnack('JSON скопирован в буфер обмена');
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
              onSnack('Генерация и скачивание PDF...');
              await DocumentExportService.downloadPdf(doc, currency);
              onSnack('Файл PDF скачан');
            },
          ),
        ],
      ),
    );
  }
}
