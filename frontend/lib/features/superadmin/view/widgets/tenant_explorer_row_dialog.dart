// ============================================================================
// Kreso Flow | Superadmin View | Tenant Explorer Row Dialog
// ============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';

// ─── 1. Row Create / Edit Modal Dialog ──────────────────────────────────────

class TenantExplorerRowDialog extends StatefulWidget {
  final bool isEdit;
  final List<Map<String, dynamic>> columns;
  final List<String> primaryKeys;
  final Map<String, dynamic>? initialData;
  final ValueChanged<Map<String, dynamic>> onSave;

  const TenantExplorerRowDialog({
    super.key,
    required this.isEdit,
    required this.columns,
    required this.primaryKeys,
    this.initialData,
    required this.onSave,
  });

  @override
  State<TenantExplorerRowDialog> createState() => _TenantExplorerRowDialogState();
}

class _TenantExplorerRowDialogState extends State<TenantExplorerRowDialog> {
  late final Map<String, dynamic> _payload;

  @override
  void initState() {
    super.initState();
    _payload = widget.initialData != null ? Map.from(widget.initialData!) : {};
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;

    return AppDialog(
      title: isEdit ? 'Редактировать запись' : 'Создать запись',
      icon: isEdit ? PhosphorIconsRegular.pencilSimple : PhosphorIconsRegular.plusCircle,
      width: 520,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 450),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.columns.map((c) {
              final colName = c['name'] as String;
              final isPk = widget.primaryKeys.contains(colName);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: TextFormField(
                  initialValue: _payload[colName]?.toString(),
                  enabled: !(isEdit && isPk),
                  decoration: InputDecoration(
                    labelText: colName + (isPk ? ' (PK)' : ''),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (val) => _payload[colName] = val.isEmpty ? null : val,
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        AppSecondaryButton(
          label: 'Отмена',
          size: AppButtonSize.md,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        AppPrimaryButton(
          label: isEdit ? 'Сохранить' : 'Создать',
          size: AppButtonSize.md,
          onPressed: () {
            Navigator.pop(context);
            widget.onSave(_payload);
          },
        ),
      ],
    );
  }
}
