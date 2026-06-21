import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:retail_os_frontend/features/pos/bloc/menu_bloc.dart';

import 'components/pos_breadcrumb_bar.dart';
import 'components/pos_category_card.dart';
import 'components/pos_item_card.dart';
import 'components/pos_empty_state.dart';

// Colour accents cycled per category card
const _kCategoryColors = [
  Color(0xFFE8A020),
  Color(0xFFFF6B35),
  Color(0xFF2DD4BF),
  Color(0xFF8B5CF6),
  Color(0xFF3B82F6),
  Color(0xFFEC4899),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
];

class PosMenuGrid extends StatefulWidget {
  const PosMenuGrid({super.key});

  @override
  State<PosMenuGrid> createState() => _PosMenuGridState();
}

class _PosMenuGridState extends State<PosMenuGrid> {
  List<dynamic> _navigationHistory = [];

  int? get _currentCategoryId =>
      _navigationHistory.isEmpty ? null : _navigationHistory.last.id;

  void _navigateUp() {
    if (_navigationHistory.isNotEmpty) {
      setState(() => _navigationHistory.removeLast());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Breadcrumb bar ────────────────────────────────────────────────
        PosBreadcrumbBar(
          history: _navigationHistory,
          onBack: _navigationHistory.isEmpty ? null : _navigateUp,
          onRoot: () => setState(() => _navigationHistory.clear()),
          onCrumb: (index) => setState(() {
            _navigationHistory = _navigationHistory.sublist(0, index + 1);
          }),
        ),

        // ── Grid ──────────────────────────────────────────────────────────
        Expanded(
          child: BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, catState) {
              return BlocBuilder<MenuBloc, MenuState>(
                builder: (context, menuState) {
                  if (catState is CategoryLoading || menuState is MenuLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<dynamic> categories = [];
                  if (catState is CategoryLoaded) {
                    categories = catState.categories
                        .where((c) =>
                            c.parentId == _currentCategoryId && c.isVisible)
                        .toList();
                  }

                  List<dynamic> items = [];
                  if (menuState is MenuLoaded) {
                    items = menuState.items.where((i) {
                      final catId = int.tryParse(i.categoryId.toString());
                      return catId == _currentCategoryId;
                    }).toList();
                  }

                  if (categories.isEmpty && items.isEmpty) {
                    return PosEmptyState(
                      inCategory: _currentCategoryId != null,
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 190,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: categories.length + items.length,
                    itemBuilder: (context, index) {
                      if (index < categories.length) {
                        final cat = categories[index];
                        final accent =
                            _kCategoryColors[index % _kCategoryColors.length];
                        return PosCategoryCard(
                          cat: cat,
                          accent: accent,
                          onTap: () => setState(
                              () => _navigationHistory.add(cat)),
                        );
                      } else {
                        final item = items[index - categories.length];
                        return PosItemCard(
                          item: item,
                          onTap: () =>
                              context.read<CartBloc>().add(AddItemToCart(item)),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
