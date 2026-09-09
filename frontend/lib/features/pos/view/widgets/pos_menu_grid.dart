import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_nav_cubit.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_settings_cubit.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:mynix_frontend/features/pos/view/widgets/components/pos_breadcrumb_bar.dart';
import 'package:mynix_frontend/features/pos/view/widgets/components/pos_empty_state.dart';
import 'package:mynix_frontend/features/pos/view/widgets/components/pos_menu_grid_view.dart';

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
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;

    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyF) {
      _openSearch();
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.f2) {
      _openSearch();
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_isSearchOpen || _searchQuery.isNotEmpty) {
        _closeSearch();
        return true;
      }
    }

    return false;
  }

  void _openSearch() {
    setState(() {
      _isSearchOpen = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
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
                                Icon(PhosphorIconsRegular.warningCircle, size: 44, color: AppColors.danger),
                                const SizedBox(height: 12),
                                Text(
                                  'Ошибка загрузки меню',
                                  style: AppTextStyles.h3.copyWith(color: AppColors.danger),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<MenuBloc>().add(LoadMenu());
                                    context.read<CategoryBloc>().add(LoadCategories());
                                  },
                                  child: const Text('Повторить попытку'),
                                ),
                              ],
                            ),
                          );
                        }

                        List<dynamic> categories = [];
                        List<dynamic> items = [];

                        final q = _searchQuery.trim().toLowerCase();
                        if (_isSearchOpen && q.isNotEmpty) {
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
                                .toList();
                          }

                          if (menuState is MenuLoaded) {
                            items = menuState.items.where((i) {
                              final catId = int.tryParse(i.categoryId.toString());
                              return catId == currentCategoryId && i.isAvailable && i.parentId == null;
                            }).toList();
                          }
                        }

                        if (categories.isEmpty && items.isEmpty) {
                          return PosEmptyState(inCategory: currentCategoryId != null || (_isSearchOpen && q.isNotEmpty));
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
