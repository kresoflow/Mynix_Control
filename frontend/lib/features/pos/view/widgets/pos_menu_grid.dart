import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_nav_cubit.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_settings_cubit.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

import 'components/pos_breadcrumb_bar.dart';
import 'components/pos_category_card.dart';
import 'components/pos_item_card.dart';
import 'components/pos_empty_state.dart';
import 'menu_modifiers_dialog.dart';

class PosMenuGrid extends StatelessWidget {
  const PosMenuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Read URL params
    final urlCategoryId = GoRouterState.of(context).uri.queryParameters['category'];
    final catState = context.read<CategoryBloc>().state;
    final posNavCubit = context.read<PosNavCubit>();

    // 2. Sync URL with Cubit if categories are loaded
    if (catState is CategoryLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        posNavCubit.syncWithUrl(context, urlCategoryId, catState.categories);
      });
    }

    return BlocBuilder<PosNavCubit, List<dynamic>>(
      builder: (context, navigationHistory) {
        final currentCategoryId = navigationHistory.isEmpty ? null : navigationHistory.last.id;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor, // Clean background
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Breadcrumb bar ────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: PosBreadcrumbBar(
                  history: navigationHistory,
                  onBack: navigationHistory.isEmpty ? null : () => posNavCubit.popCategory(context),
                  onRoot: () => posNavCubit.clearHistory(context),
                  onCrumb: (index) => posNavCubit.popTo(context, index),
                ),
              ),

              // ── Grid ──────────────────────────────────────────────────────────
              Expanded(
                child: BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, catState) {
                    return BlocBuilder<MenuBloc, MenuState>(
                      builder: (context, menuState) {
                        if (catState is CategoryLoading || menuState is MenuLoading) {
                          // Premium skeleton loading
                          return Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
                        }

                        List<dynamic> categories = [];
                        if (catState is CategoryLoaded) {
                          categories = catState.categories
                              .where((c) => c.parentId == currentCategoryId && c.isVisible && c.categoryType != 'ingredient')
                              .toList();
                        }

                        List<dynamic> items = [];
                        if (menuState is MenuLoaded) {
                          items = menuState.items.where((i) {
                            final catId = int.tryParse(i.categoryId.toString());
                            return catId == currentCategoryId && i.isAvailable && i.parentId == null;
                          }).toList();
                        }

                        if (categories.isEmpty && items.isEmpty) {
                          return PosEmptyState(
                            inCategory: currentCategoryId != null,
                          );
                        }

                        return BlocBuilder<PosSettingsCubit, PosSettingsState>(
                          builder: (context, posSettings) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            final isMobile = screenWidth < 600;
                            
                            return GridView.builder(
                              padding: EdgeInsets.fromLTRB(
                                isMobile ? 12 : 24, 
                                isMobile ? 12 : 24, 
                                isMobile ? 12 : 24, 
                                isMobile ? 120 : 24, // Extra bottom padding for floating cart on mobile
                              ),
                              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: isMobile ? (screenWidth / 2) - 16 : posSettings.cardSize, 
                                childAspectRatio: isMobile ? 0.9 : 0.85,
                                crossAxisSpacing: isMobile ? 12 : 20,
                                mainAxisSpacing: isMobile ? 12 : 20,
                              ),
                              itemCount: categories.length + items.length,
                              itemBuilder: (context, index) {
                                if (index < categories.length) {
                                  final cat = categories[index];
                                  final accent = posSettings.enableRainbowColors 
                                      ? AppColors.categoryRainbowPalette[index % AppColors.categoryRainbowPalette.length]
                                      : AppColors.brandPrimary;
                                  return PosCategoryCard(
                                    cat: cat,
                                    accent: accent,
                                    onTap: () => posNavCubit.pushCategory(context, cat),
                                  );
                                } else {
                                  final item = items[index - categories.length];
                                  return PosItemCard(
                                    item: item,
                                    onTap: () async {
                                      final List<MenuItem> allItems = context.read<MenuBloc>().state is MenuLoaded 
                                          ? (context.read<MenuBloc>().state as MenuLoaded).items 
                                          : <MenuItem>[];
                                      final MenuItem menuItem = item as MenuItem;
                                      final children = allItems.where((i) => i.parentId == menuItem.id).toList();
                                      bool hasOptions = children.isNotEmpty;
                                      bool hasExactlyOneVariation = false;
                                      Map<String, dynamic>? singleVariation;
                                      List<dynamic>? variations;
                                      List<dynamic>? modifiers;

                                      if (item.attributesJson != null && item.attributesJson!.isNotEmpty && item.attributesJson != '{}') {
                                         try {
                                            final attrs = jsonDecode(item.attributesJson!);
                                            variations = attrs['variations'] as List?;
                                            modifiers = attrs['modifier_groups'] as List?;
                                            if ((variations != null && variations.isNotEmpty) || (modifiers != null && modifiers.isNotEmpty)) {
                                               hasOptions = true;
                                            }
                                         } catch (_) {}
                                      }
                                      
                                      if (hasOptions && (modifiers == null || modifiers.isEmpty)) {
                                          int varCount = variations != null ? variations.length : 0;
                                          int childCount = children.length;
                                          
                                          if (varCount <= 1 && childCount <= 1 && (varCount == 1 || childCount == 1)) {
                                              hasExactlyOneVariation = true;
                                              if (varCount == 1) {
                                                  singleVariation = Map<String, dynamic>.from(variations!.first as Map);
                                              } else {
                                                  singleVariation = {
                                                      'name': children.first.name,
                                                      'price': children.first.price,
                                                  };
                                              }
                                              if (childCount == 1) {
                                                  singleVariation['id'] = children.first.id;
                                              }
                                          }
                                      }

                                      if (hasExactlyOneVariation) {
                                          final selected = <String, dynamic>{};
                                          selected['variation'] = singleVariation!['name'];
                                          if (singleVariation['id'] != null) {
                                            selected['child_item_id'] = singleVariation['id'];
                                          }
                                          
                                          final varPrice = (singleVariation['price'] as num?)?.toDouble() ?? 0.0;
                                          final additional = varPrice - item.price;
                                          
                                          context.read<CartBloc>().add(AddItemToCart(
                                            item,
                                            selectedOptionsJson: jsonEncode(selected),
                                            selectedOptionsPrice: additional,
                                          ));
                                      } else if (hasOptions) {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => MenuModifiersDialog(
                                            item: item,
                                            childrenItems: children,
                                            onAdd: (result) {
                                              context.read<CartBloc>().add(AddItemToCart(
                                                item,
                                                selectedOptionsJson: result['json'],
                                                selectedOptionsPrice: result['price'],
                                              ));
                                            },
                                          ),
                                        );
                                      } else {
                                        context.read<CartBloc>().add(AddItemToCart(item));
                                      }
                                    },
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
