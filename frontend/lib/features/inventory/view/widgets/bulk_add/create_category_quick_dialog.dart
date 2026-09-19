import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';

void showCreateCategoryQuickDialog({
  required BuildContext context,
  required String type,
  int? parentId,
  String? parentName,
}) {
  final nameCtrl = TextEditingController();
  bool asSubcategory = parentId != null;

  showDialog(
    context: context,
    builder: (ctx) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Новая категория',
              style: TextStyle(
                color: isDark ? AppColors.darkText : AppColors.lightText,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                if (parentId != null) ...[
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: Text(
                      'Создать внутри «$parentName»',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    value: asSubcategory,
                    onChanged: (val) {
                      setStateDialog(() {
                        asSubcategory = val ?? false;
                      });
                    },
                  ),
                ],
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              AppGhostButton(
                label: 'Отмена',
                size: AppButtonSize.md,
                onPressed: () => Navigator.pop(ctx),
              ),
              const SizedBox(width: 8),
              AppPrimaryButton(
                label: 'Создать',
                size: AppButtonSize.md,
                onPressed: () {
                  final text = nameCtrl.text.trim();
                  if (text.isNotEmpty) {
                    context.read<CategoryBloc>().add(
                      CreateCategory(
                        name: text,
                        categoryType: type,
                        parentId: asSubcategory ? parentId : null,
                      ),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Категория добавляется...'),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}
