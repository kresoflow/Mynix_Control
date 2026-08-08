import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/write_off_dialog.dart';
import 'package:mynix_frontend/core/widgets/skeleton_loader.dart';

class WriteOffTab extends StatefulWidget {
  const WriteOffTab({super.key});

  @override
  State<WriteOffTab> createState() => _WriteOffTabState();
}

class _WriteOffTabState extends State<WriteOffTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('Все')),
              ButtonSegment(value: 'raw', label: Text('Сырье для кухни')),
              ButtonSegment(value: 'retail', label: Text('Товары для витрины')),
            ],
            selected: {_filter},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _filter = newSelection.first;
              });
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<IngredientBloc, IngredientState>(
            builder: (context, state) {
              if (state is IngredientLoading) {
                return const SkeletonList();
              } else if (state is IngredientLoaded) {
                final filtered = state.ingredients.where((item) {
                  final isRetail =
                      item.attributes != null &&
                      item.attributes!['is_retail'] == true;
                  if (_filter == 'retail') return isRetail;
                  if (_filter == 'raw') return !isRetail;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Нет товаров в этой категории.'),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isRetail =
                              item.attributes != null &&
                              item.attributes!['is_retail'] == true;

                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                isRetail ? PhosphorIconsRegular.storefront : PhosphorIconsRegular.cookingPot,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(fontSize: 16),
                              ),
                              subtitle: Text(
                                'Остаток: ${item.currentStock} ${item.unit}',
                              ),
                              trailing: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.errorContainer,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                                onPressed: () =>
                                    WriteOffDialog.show(context, item),
                                icon: const Icon(PhosphorIconsRegular.minus, size: 18),
                                label: const Text('Списание'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }
              return const Center(child: Text('Ошибка загрузки склада'));
            },
          ),
        ),
      ],
    );
  }
}
