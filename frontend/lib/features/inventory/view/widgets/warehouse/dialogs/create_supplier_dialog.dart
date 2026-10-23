// ==============================================================================
// МОДУЛЬ: Склад / Диалог создания поставщика
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/create_supplier_dialog.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

// ─── 1. Диалог добавления нового поставщика ──────────────────────────────────
/// [UI-KIT] Модальное окно добавления контрагента на базе эталонного AppDialog.
class CreateSupplierDialog extends StatefulWidget {
  const CreateSupplierDialog({super.key});

  @override
  State<CreateSupplierDialog> createState() => _CreateSupplierDialogState();
}

class _CreateSupplierDialogState extends State<CreateSupplierDialog> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.showError(context, 'Введите название поставщика');
      return;
    }

    final result = {
      'name': name,
      'contact_info': _contactController.text.trim().isEmpty
          ? null
          : _contactController.text.trim(),
    };
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Новый поставщик',
      subtitle: 'Создание контрагента для поставок',
      icon: PhosphorIconsRegular.truck,
      width: 460,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            labelText: 'Название поставщика',
            hintText: 'Например: ОсОО «Берекет»',
            controller: _nameController,
            autofocus: true,
            prefixIcon: const Icon(PhosphorIconsRegular.buildings, size: 18),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          AppTextField(
            labelText: 'Контактные данные (необязательно)',
            hintText: '+996 555 12-34-56 / менеджер',
            controller: _contactController,
            prefixIcon: const Icon(PhosphorIconsRegular.phone, size: 18),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        AppGhostButton(
          label: 'Отмена',
          onPressed: () => Navigator.pop(context),
        ),
        AppPrimaryButton(
          label: 'Создать',
          onPressed: _save,
        ),
      ],
    );
  }
}
