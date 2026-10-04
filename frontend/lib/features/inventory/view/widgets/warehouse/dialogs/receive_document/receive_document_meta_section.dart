import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_event.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_state.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/create_supplier_dialog.dart';
import 'receive_document_meta_row.dart';

class ReceiveDocumentMetaSection extends StatelessWidget {
  final int? selectedSupplierId;
  final ValueChanged<int?> onSupplierChanged;
  final TextEditingController invoiceController;
  final TextEditingController reasonController;
  final DateTime documentDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool isAdHocPurchase;
  final ValueChanged<bool> onAdHocChanged;

  const ReceiveDocumentMetaSection({
    super.key,
    required this.selectedSupplierId,
    required this.onSupplierChanged,
    required this.invoiceController,
    required this.reasonController,
    required this.documentDate,
    required this.onDateChanged,
    required this.isAdHocPurchase,
    required this.onAdHocChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentBloc, DocumentState>(
      builder: (blocCtx, state) {
        return ReceiveDocumentMetaRow(
          suppliers: state.suppliers,
          selectedSupplierId: selectedSupplierId,
          onSupplierChanged: onSupplierChanged,
          onAddSupplier: () async {
            final result = await showDialog<Map<String, dynamic>>(
              context: blocCtx,
              builder: (dialogCtx) => const CreateSupplierDialog(),
            );
            if (result != null && blocCtx.mounted) {
              blocCtx.read<DocumentBloc>().add(
                CreateSupplier(result['name'], contactInfo: result['contact_info']),
              );
            }
          },
          invoiceController: invoiceController,
          reasonController: reasonController,
          documentDate: documentDate,
          onDateChanged: onDateChanged,
          isAdHocPurchase: isAdHocPurchase,
          onAdHocChanged: onAdHocChanged,
        );
      },
    );
  }
}
