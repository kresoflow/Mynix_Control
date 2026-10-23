import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_nav_cubit.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_settings_cubit.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/features/pos/view/widgets/components/pos_breadcrumb_bar.dart';
import 'package:kreso_frontend/features/pos/view/widgets/components/pos_empty_state.dart';
import 'package:kreso_frontend/features/pos/view/widgets/components/pos_menu_grid_view.dart';

class PosMenuGrid extends StatefulWidget {
  const PosMenuGrid({super.key});

  @override
  State<PosMenuGrid> createState() => _PosMenuGridState();
}

class _PosMenuGridState extends State<PosMenuGrid> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchOpen = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _isSearchOpen = true);
  }

  void _closeSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearchOpen = false;
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final urlCategoryId = GoRouterState.of(context).uri.queryParameters['category'];
    final catState = context.read<CategoryBloc>().state;
    final posNavCubit = context.read<PosNavCubit>();

    if (catState is CategoryLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        posNavCubit.syncWithUrl(context, urlCategoryId, catState.categories);
      });
    }

    return BlocBuilder<PosNavCubit, List<dynamic>>(
      builder: (context, navigationHistory) {
        final currentCategoryId = navigationHistory.isEmpty ? null : navigationHistory.last.id;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: AppShadows.light,
                ),
                child: PosBreadcrumbBar(
                  history: navigationHistory,
                  onBack: navigationHistory.isEmpty ? null : () => posNavCubit.popCategory(context),
                  onRoot: () => posNavCubit.clearHistory(context),
                  onCrumb: (index) => posNavCubit.popTo(context, index),
                  isSearchOpen: _isSearchOpen,
                  onOpenSearch: _openSearch,
                  onCloseSearch: _closeSearch,
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  onSearchChanged: (q) => setState(() => _searchQuery = q),
                ),
              ),
              Expanded(
                child: BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, catState) {
                    return BlocBuilder<MenuBloc, MenuState>(
                      builder: (context, menuState) {
                        if (catState is CategoryLoading || menuState is MenuLoading) {
                          return Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
                        }

                        if (catState is CategoryError || menuState is MenuError) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(PhosphorIconsRegular.warningCircle, size: 44, color: AppColors.danger),
                                const SizedBox(height: 12),
                                Text(
                                  'Ошибка загрузки меню',
                                  style: AppTextStyles.h3.copyWith(color: AppColors.danger),
                                ),
                                const SizedBox(height: 12),
                                AppPrimaryButton(
                                  label: 'Повторить попытку',
                                  onPressed: () {
                                    context.read<MenuBloc>().add(LoadMenu());
                                    context.read<CategoryBloc>().add(LoadCategories());
                                  },
                                ),
                              ],
                            ),
                          );
                        }

                        List<dynamic> categories = [];
                        List<dynamic> items = [];

                        final q = _searchQuery.trim().toLowerCase();
                        if (q.isNotEmpty) {
                          if (menuState is MenuLoaded) {
                            items = menuState.items.where((i) {
                              final nameMatch = i.cleanName.toLowerCase().contains(q) || i.name.toLowerCase().contains(q);
                              final shortNameMatch = i.shortName != null && i.shortName!.toLowerCase().contains(q);
                              final barcodeMatch = i.barcode != null && i.barcode!.toLowerCase().contains(q);
                              return (nameMatch || shortNameMatch || barcodeMatch) && i.isAvailable && i.parentId == null;
                            }).toList();
                          }
                        } else {
                          if (catState is CategoryLoaded) {
                            categories = catState.categories
                                .where((c) => c.parentId == currentCategoryId && c.isVisible && !c.isArchived && c.categoryType != 'ingredient')
                                .toList()
                              ..sort((a, b) {
                                final sortA = a.sortOrder == 0 ? 999999 : a.sortOrder;
                                final sortB = b.sortOrder == 0 ? 999999 : b.sortOrder;
                                final cmp = sortA.compareTo(sortB);
                                return cmp != 0 ? cmp : a.id.compareTo(b.id);
                              });
                          }

                          if (menuState is MenuLoaded) {
                            items = menuState.items.where((i) {
                              final catIdStr = i.categoryId.toString();
                              final catId = int.tryParse(catIdStr);
                              final isRootItem = catId == null || catId == 0 || catIdStr == '0' || catIdStr == 'null' || catIdStr == 'uncategorized' || catIdStr == '';
                              final inCurrentCategory = currentCategoryId == null ? isRootItem : (catId == currentCategoryId);
                              return inCurrentCategory && i.isAvailable && i.parentId == null;
                            }).toList()
                              ..sort((a, b) {
                                final sortA = a.sortOrder == 0 ? 999999 : a.sortOrder;
                                final sortB = b.sortOrder == 0 ? 999999 : b.sortOrder;
                                final cmp = sortA.compareTo(sortB);
                                return cmp != 0 ? cmp : a.id.compareTo(b.id);
                              });
                          }
                        }

                        if (categories.isEmpty && items.isEmpty) {
                          return PosEmptyState(inCategory: currentCategoryId != null || q.isNotEmpty);
                        }

                        return BlocBuilder<PosSettingsCubit, PosSettingsState>(
                          builder: (context, posSettings) {
                            return PosMenuGridView(
                              categories: categories,
                              items: items,
                              posSettings: posSettings,
                              onCategoryTap: (cat) => posNavCubit.pushCategory(context, cat),
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
