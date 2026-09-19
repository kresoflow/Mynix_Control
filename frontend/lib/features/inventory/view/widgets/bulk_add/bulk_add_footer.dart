import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';

class BulkAddFooter extends StatelessWidget {
  final VoidCallback onSaveAll;

  const BulkAddFooter({super.key, required this.onSaveAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppGhostButton(
          label: 'Отмена',
          size: AppButtonSize.lg,
          onPressed: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: 12),
        AppPrimaryButton(
          label: 'Сохранить всё',
          icon: PhosphorIconsRegular.floppyDisk,
          size: AppButtonSize.lg,
          tooltip: 'Ctrl+S',
          onPressed: onSaveAll,
        ),
      ],
    );
  }
}
