import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';

class BulkAddFooter extends StatelessWidget {
  final VoidCallback onSaveAll;

  const BulkAddFooter({super.key, required this.onSaveAll});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: AppButton.primary(
        label: 'Сохранить всё (Ctrl+S)',
        icon: PhosphorIconsRegular.floppyDisk,
        height: 46,
        onPressed: onSaveAll,
      ),
    );
  }
}
