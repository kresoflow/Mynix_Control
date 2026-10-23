import 'menu_item_modal.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/widgets/skeleton_loader.dart';


class MenuManagerItemsGrid extends StatelessWidget {
  final int? currentParentId;
  final Function(int) onDelete;

  const MenuManagerItemsGrid({
    super.key,
    required this.currentParentId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (currentParentId == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Text(
          'Выберите папку, чтобы просмотреть товары',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
      );
    }

    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        if (state is MenuLoading) {
          return const SkeletonGrid(gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1));
        } else if (state is MenuLoaded) {
          final items = state.items
              .where((item) => item.categoryId == currentParentId.toString())
              .toList();

          if (items.isEmpty) {
            return const Center(
              child: Text('Нет товаров в этой категории. Создайте новый!'),
            );
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  borderRadius: AppRadii.radiusLg,
                ),
                child: ListTile(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => MenuItemModal(existingItem: item),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Icon(
                      PhosphorIconsRegular.hamburger,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    item.cleanName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    item.attributesString != null
                        ? '${item.attributesString}\n${item.variationPrices != null && item.variationPrices!.isNotEmpty ? item.variationPrices!.map((p) => (p as num).toCurrency(context)).join(" | ") : "${item.price} с"}'
                        : (item.price as num).toCurrency(context),
                    style: AppTextStyles.h3,
                  ),
                  trailing: IconButton(
                    icon: const Icon(PhosphorIconsRegular.trash, color: AppColors.danger, size: 20),
                    onPressed: () => onDelete(item.id),
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
