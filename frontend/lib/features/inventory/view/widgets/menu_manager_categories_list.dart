import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_event.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/dialogs/create_category_dialog.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class MenuManagerCategoriesList extends StatelessWidget {
  final int? currentParentId;
  final Function(MenuCategory) onNavigate;
  final Function(int) onDelete;

  const MenuManagerCategoriesList({
    super.key,
    required this.currentParentId,
    required this.onNavigate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CategoryLoaded) {
          final subCategories = state.categories
              .where((c) => c.parentId == currentParentId)
              .toList();

          return Column(
            children: [
              Expanded(
                child: subCategories.isEmpty
                    ? const Center(
                        child: Text('Нет подкатегорий. Создайте новую папку.'),
                      )
                    : ListView.builder(
                        itemCount: subCategories.length,
                        itemBuilder: (context, index) {
                          final cat = subCategories[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () => onNavigate(cat),
                              leading: IconHelper.buildIcon(
                                cat.icon,
                                size: 36,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                cat.name,
                                style: AppTextStyles.h3,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: cat.isVisible,
                                    onChanged: (val) {
                                      context.read<CategoryBloc>().add(
                                        UpdateCategory(id: cat.id, isVisible: val),
                                      );
                                    },
                                    activeThumbColor: Theme.of(context).colorScheme.primary,
                                  ),
                                  IconButton(
                                    icon: const Icon(PhosphorIconsRegular.trash, color: Colors.red),
                                    onPressed: () => onDelete(cat.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showAddCategoryDialog(
                      context,
                      currentCategoryId: currentParentId,
                      type: 'ingredient',
                    );
                  },
                  icon: const Icon(PhosphorIconsRegular.folderPlus),
                  label: const Text('Создать категорию'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
