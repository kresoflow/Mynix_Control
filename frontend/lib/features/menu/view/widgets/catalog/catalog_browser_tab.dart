import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_event.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'package:mynix_frontend/features/pos/view/widgets/menu_modifiers_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'catalog_dialogs.dart';
import 'catalog_header.dart';
import 'catalog_content_view.dart';
import 'catalog_enums.dart';
import 'catalog_skeleton.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class CatalogBrowserTab extends StatefulWidget {
  final String categoryType;
  final String rootTitle;
  final bool Function(MenuItem) itemFilter;
  final Widget Function(BuildContext context, int? categoryId)? addMenuBuilder;
  final String emptyMessage;

  const CatalogBrowserTab({
    super.key,
    required this.categoryType,
    required this.rootTitle,
    required this.itemFilter,
    this.addMenuBuilder,
    this.emptyMessage = 'Здесь пока пусто. Нажмите "Добавить".',
  });

  @override
  State<CatalogBrowserTab> createState() => _CatalogBrowserTabState();
}

class _CatalogBrowserTabState extends State<CatalogBrowserTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<dynamic> _navigationHistory = [];
  CategoryManageMode _manageMode = CategoryManageMode.none;
  CategoryViewMode _viewMode = CategoryViewMode.grid;
  Set<int> _selectedCategories = {};
  Set<int> _selectedItems = {};
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadViewMode();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('category_view_mode');
    if (mode == 'list' && mounted) {
      setState(() {
        _viewMode = CategoryViewMode.list;
      });
    }
  }

  Future<void> _saveViewMode(CategoryViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('category_view_mode', mode == CategoryViewMode.list ? 'list' : 'grid');
  }

  int? get _currentCategoryId => _navigationHistory.isEmpty ? null : _navigationHistory.last.id;

  void _showAddDialog(BuildContext context) {
    String parentType = 'dish';
    final catState = context.read<CategoryBloc>().state;
    if (catState is CategoryLoaded && _currentCategoryId != null) {
      final parentCat = catState.categories.where((c) => c.id == _currentCategoryId).firstOrNull;
      if (parentCat != null) parentType = parentCat.categoryType;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(PhosphorIconsRegular.squaresFour),
                title: const Text('Создать подкатегорию'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddCategoryDialog(context, currentCategoryId: _currentCategoryId, type: parentType);
                },
              ),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.hamburger),
                title: const Text('Добавить блюдо'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddMenuItemDialog(context, currentCategoryId: _currentCategoryId);
                },
              ),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.storefront),
                title: const Text('Добавить товар (витрина)'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddRetailProductDialog(context, currentCategoryId: _currentCategoryId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<CategoryBloc, CategoryState>(
            listener: (context, state) {
              if (state is CategoryError) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.danger));
            },
          ),
          BlocListener<MenuBloc, MenuState>(
            listener: (context, state) {
              if (state is MenuError) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.warning));
            },
          ),
        ],
        child: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, catState) {
            return BlocBuilder<MenuBloc, MenuState>(
              builder: (context, menuState) {
                final bool isLoading = catState is CategoryLoading || menuState is MenuLoading;

                List<dynamic> currentCategories = [];
                if (catState is CategoryLoaded) {
                  currentCategories = catState.categories
                      .where((c) {
                        if (c.parentId != _currentCategoryId) return false;
                        if (widget.categoryType == 'all') {
                          return c.categoryType != 'ingredient';
                        }
                        return c.categoryType == widget.categoryType;
                      })
                      .toList();
                }

                List<dynamic> currentItems = [];
                if (menuState is MenuLoaded) {
                  final currentCatStr = _currentCategoryId?.toString();
                  currentItems = menuState.items.where((i) {
                    if (!_showArchived && !i.isAvailable) return false;
                    final iCatStr = i.categoryId.toString();
                    final isRootItem = iCatStr == '0' || iCatStr == 'null' || iCatStr == 'uncategorized' || iCatStr == '';
                    final inCategory = iCatStr == currentCatStr || (isRootItem && currentCatStr == null);
                    return inCategory && i.parentId == null && widget.itemFilter(i);
                  }).toList();
                }

                final int selectedCount = _selectedCategories.length + _selectedItems.length;
                final bool isAllSelected = currentCategories.isNotEmpty || currentItems.isNotEmpty
                    ? selectedCount == (currentCategories.length + currentItems.length)
                    : false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CatalogHeader(
                      manageMode: _manageMode,
                      viewMode: _viewMode,
                      selectedCount: selectedCount,
                      isAllSelected: isAllSelected,
                      navigationHistory: _navigationHistory,
                      currentCategoryId: _currentCategoryId,
                      showArchived: _showArchived,
                      rootTitle: widget.rootTitle,
                      onShowArchivedToggle: () {
                        setState(() {
                          _showArchived = !_showArchived;
                        });
                      },
                      addMenuBuilder: widget.addMenuBuilder,
                      onManageModeChanged: (mode) {
                        setState(() {
                          _manageMode = mode;
                          if (mode == CategoryManageMode.delete) {
                            _selectedCategories.clear();
                            _selectedItems.clear();
                          }
                        });
                      },
                      onViewModeChanged: (mode) {
                        setState(() {
                          _viewMode = mode;
                          _saveViewMode(mode);
                        });
                      },
                      onSelectAllToggle: () {
                        setState(() {
                          if (isAllSelected) {
                            _selectedCategories.clear();
                            _selectedItems.clear();
                          } else {
                            _selectedCategories = currentCategories.map((c) => c.id as int).toSet();
                            _selectedItems = currentItems.map((i) => i.id as int).toSet();
                          }
                        });
                      },
                      onClearSelection: () {
                        setState(() {
                          _manageMode = CategoryManageMode.none;
                          _selectedCategories.clear();
                          _selectedItems.clear();
                        });
                      },
                      onDeleteSelected: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => MynixDialog(
                            title: 'Массовое удаление',
                            icon: PhosphorIconsRegular.trash,
                            isDestructive: true,
                            content: Text(
                              'Удалить выбранные элементы ($selectedCount шт.)?\nЭто действие нельзя отменить.',
                              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.lightSubtext), // Or context dependent, MynixDialog handles dark mode usually. Better to just use Text
                            ),
                            actions: [
                              AppGhostButton(
                                label: 'Отмена',
                                onPressed: () => Navigator.pop(ctx),
                              ),
                              const SizedBox(width: 12),
                              AppDangerButton(
                                label: 'Удалить',
                                icon: PhosphorIconsRegular.trash,
                                onPressed: () {
                                  for (var itemId in _selectedItems) {
                                    context.read<MenuBloc>().add(DeleteMenuItem(itemId));
                                  }
                                  for (var catId in _selectedCategories) {
                                    context.read<CategoryBloc>().add(DeleteCategory(catId, mode: 'all'));
                                  }
                                  setState(() {
                                    _selectedItems.clear();
                                    _selectedCategories.clear();
                                    _manageMode = CategoryManageMode.none;
                                  });
                                  Navigator.pop(ctx);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      onNavigateUp: () {
                        if (_navigationHistory.isNotEmpty) setState(() => _navigationHistory.removeLast());
                      },
                      onNavigateToRoot: () {
                        setState(() => _navigationHistory.clear());
                      },
                      onNavigateToHistory: (index) {
                        setState(() => _navigationHistory = _navigationHistory.sublist(0, index + 1));
                      },
                      onAddPressed: () => _showAddDialog(context),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (isLoading) return CatalogSkeleton(isList: _viewMode == CategoryViewMode.list);
                          
                          return CatalogContentView(
                            currentCategories: currentCategories,
                            currentItems: currentItems,
                            viewMode: _viewMode,
                            manageMode: _manageMode,
                            selectedCategories: _selectedCategories,
                            selectedItems: _selectedItems,
                            emptyMessage: widget.emptyMessage,
                            onCategoryTap: (cat) {
                              if (_manageMode == CategoryManageMode.delete) {
                                setState(() => _selectedCategories.contains(cat.id) ? _selectedCategories.remove(cat.id) : _selectedCategories.add(cat.id));
                              } else if (_manageMode == CategoryManageMode.none) {
                                setState(() => _navigationHistory.add(cat));
                              }
                            },
                            onCategoryToggle: (cat, val) => setState(() => val == true ? _selectedCategories.add(cat.id) : _selectedCategories.remove(cat.id)),
                            onCategoryVisibilityToggle: (cat) => context.read<CategoryBloc>().add(UpdateCategory(id: cat.id, isVisible: !cat.isVisible)),
                            onCategoryEdit: (cat) => showAddCategoryDialog(context, currentCategoryId: _currentCategoryId, itemToEdit: cat),
                            onCategoryDelete: (cat) => context.read<CategoryBloc>().add(DeleteCategory(cat.id, mode: 'all')),
                            onItemTap: (item) async {
                              if (_manageMode == CategoryManageMode.delete) {
                                setState(() => _selectedItems.contains(item.id) ? _selectedItems.remove(item.id) : _selectedItems.add(item.id));
                              } else if (_manageMode == CategoryManageMode.none) {
                                  bool hasOptions = false;
                                  List<dynamic>? variations;
                                  List<dynamic>? modifiers;
                                  if (item.attributesJson != null && item.attributesJson!.isNotEmpty && item.attributesJson != '{}') {
                                     try {
                                        final attrs = jsonDecode(item.attributesJson!);
                                        variations = attrs['variations'] as List?;
                                        modifiers = attrs['modifier_groups'] as List?;
                                        if ((variations != null && variations.length > 1) || (modifiers != null && modifiers.isNotEmpty)) {
                                           hasOptions = true;
                                        }
                                     } catch (_) {}
                                  }
                                  if (hasOptions) {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => MenuModifiersDialog(item: item, isReadOnly: true),
                                    );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('У этого блюда нет опций для предпросмотра.')),
                                  );
                                }
                              }
                            },
                            onItemToggle: (item, val) => setState(() => val == true ? _selectedItems.add(item.id) : _selectedItems.remove(item.id)),
                            onItemEdit: (item) => showAddMenuItemDialog(context, itemToEdit: item),
                            onItemDelete: (item) => context.read<MenuBloc>().add(DeleteMenuItem(item.id)),
                            onItemRestore: (item) => context.read<MenuBloc>().add(UpdateMenuItem(item.id, {'is_available': true})),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
