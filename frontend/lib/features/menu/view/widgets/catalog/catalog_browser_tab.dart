import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/features/pos/view/widgets/menu_modifiers_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'catalog_dialogs.dart';
import 'catalog_header.dart';
import 'catalog_content_view.dart';
import 'catalog_enums.dart';
import 'catalog_skeleton.dart';
import 'catalog_deletion_dialogs.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';

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
  final Set<int> _selectedCategories = {};
  final Set<int> _selectedItems = {};
  bool _showArchived = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadViewMode();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('category_view_mode');
    if (mode == 'list' && mounted) {
      setState(() => _viewMode = CategoryViewMode.list);
    }
  }

  Future<void> _saveViewMode(CategoryViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('category_view_mode', mode == CategoryViewMode.list ? 'list' : 'grid');
  }

  int? get _currentCategoryId => _navigationHistory.isEmpty ? null : _navigationHistory.last.id;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<CategoryBloc, CategoryState>(
            listener: (context, state) {
              if (state is CategoryLoaded) {
                context.read<MenuBloc>().add(LoadMenu());
              }
              if (state is CategoryError) {
                AppToast.showError(
                  context,
                  'Ошибка категории',
                  subtitle: state.message,
                );
              }
            },
          ),
          BlocListener<MenuBloc, MenuState>(
            listener: (context, state) {
              if (state is MenuError) {
                AppToast.showError(
                  context,
                  'Ошибка каталога',
                  subtitle: state.message,
                );
              }
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
                  currentCategories = catState.categories.where((c) {
                    if (!_showArchived && c.isArchived) return false;
                    if (widget.categoryType == 'all' && c.categoryType == 'ingredient') return false;
                    if (widget.categoryType != 'all' && c.categoryType != widget.categoryType) return false;
                    if (_searchQuery.isNotEmpty) {
                      return c.name.toLowerCase().contains(_searchQuery);
                    }
                    return c.parentId == _currentCategoryId;
                  }).toList()
                    ..sort((a, b) {
                      final sortA = a.sortOrder == 0 ? 999999 : a.sortOrder;
                      final sortB = b.sortOrder == 0 ? 999999 : b.sortOrder;
                      final cmp = sortA.compareTo(sortB);
                      return cmp != 0 ? cmp : a.id.compareTo(b.id);
                    });
                }

                List<dynamic> currentItems = [];
                if (menuState is MenuLoaded) {
                  final currentCatStr = _currentCategoryId?.toString();
                  currentItems = menuState.items.where((i) {
                    if (!_showArchived && !i.isAvailable) return false;
                    if (!widget.itemFilter(i)) return false;
                    if (i.parentId != null) return false;

                    if (_searchQuery.isNotEmpty) {
                      final name = i.cleanName.toLowerCase();
                      final barcode = i.barcode?.toLowerCase() ?? '';
                      return name.contains(_searchQuery) || barcode.contains(_searchQuery);
                    }

                    final iCatStr = i.categoryId.toString();
                    final isRootItem = iCatStr == '0' || iCatStr == 'null' || iCatStr == 'uncategorized' || iCatStr == '';
                    return iCatStr == currentCatStr || (isRootItem && currentCatStr == null);
                  }).toList()
                    ..sort((a, b) {
                      final sortA = a.sortOrder == 0 ? 999999 : a.sortOrder;
                      final sortB = b.sortOrder == 0 ? 999999 : b.sortOrder;
                      final cmp = sortA.compareTo(sortB);
                      return cmp != 0 ? cmp : a.id.compareTo(b.id);
                    });
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
                      rootTitle: widget.rootTitle,
                      showArchived: _showArchived,
                      onSearchChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      onShowArchivedToggle: () => setState(() => _showArchived = !_showArchived),
                      onManageModeChanged: (mode) => setState(() {
                        _manageMode = mode;
                        _selectedCategories.clear();
                        _selectedItems.clear();
                      }),
                      onViewModeChanged: (mode) {
                        setState(() => _viewMode = mode);
                        _saveViewMode(mode);
                      },
                      onSelectAllToggle: () => setState(() {
                        if (isAllSelected) {
                          _selectedCategories.clear();
                          _selectedItems.clear();
                        } else {
                          _selectedCategories.addAll(currentCategories.map((c) => c.id as int));
                          _selectedItems.addAll(currentItems.map((i) => i.id as int));
                        }
                      }),
                      onClearSelection: () => setState(() {
                        _selectedCategories.clear();
                        _selectedItems.clear();
                        _manageMode = CategoryManageMode.none;
                      }),
                      onDeleteSelected: () => CatalogDeletionDialogs.confirmDeleteSelected(
                        context: context,
                        selectedItems: _selectedItems,
                        selectedCategories: _selectedCategories,
                        onCleared: () => setState(() {
                          _selectedCategories.clear();
                          _selectedItems.clear();
                          _manageMode = CategoryManageMode.none;
                        }),
                      ),
                      onNavigateUp: () => setState(() => _navigationHistory.removeLast()),
                      onNavigateToRoot: () => setState(() => _navigationHistory.clear()),
                      onNavigateToHistory: (index) => setState(() => _navigationHistory = _navigationHistory.sublist(0, index + 1)),
                      onAddPressed: () => showAddCategoryDialog(context, currentCategoryId: _currentCategoryId),
                      addMenuBuilder: widget.addMenuBuilder,
                    ),
                    Expanded(
                      child: isLoading
                          ? const CatalogSkeleton()
                          : CatalogContentView(
                              viewMode: _viewMode,
                              manageMode: _manageMode,
                              currentCategories: currentCategories,
                              currentItems: currentItems,
                              selectedCategories: _selectedCategories,
                              selectedItems: _selectedItems,
                              emptyMessage: widget.emptyMessage,
                              onCategoryTap: (category) => setState(() => _navigationHistory.add(category)),
                              onCategoryToggle: (cat, val) => setState(() => _selectedCategories.contains(cat.id) ? _selectedCategories.remove(cat.id) : _selectedCategories.add(cat.id)),
                              onCategoryVisibilityToggle: (cat) => context.read<CategoryBloc>().add(UpdateCategory(id: cat.id, isVisible: !cat.isVisible)),
                              onCategoryEdit: (cat) => showAddCategoryDialog(context, itemToEdit: cat, currentCategoryId: _currentCategoryId),
                              onCategoryDelete: (cat) => CatalogDeletionDialogs.confirmDeleteCategory(context, cat),
                              onCategoryRestore: (cat) => context.read<CategoryBloc>().add(RestoreCategory(cat.id)),
                              onItemToggle: (item, val) => setState(() => _selectedItems.contains(item.id) ? _selectedItems.remove(item.id) : _selectedItems.add(item.id)),
                              onItemEdit: (item) => item.isRetail
                                  ? showAddRetailProductDialog(context, itemToEdit: item, currentCategoryId: _currentCategoryId)
                                  : showAddMenuItemDialog(context, itemToEdit: item, currentCategoryId: _currentCategoryId),
                              onItemDelete: (item) => CatalogDeletionDialogs.confirmDeleteItem(context, item),
                              onItemRestore: (item) {
                                context.read<MenuBloc>().add(UpdateMenuItem(item.id, {'is_available': true}));
                                context.read<CategoryBloc>().add(LoadCategories());
                              },
                              onItemTap: (item) {
                                if (_manageMode == CategoryManageMode.delete) {
                                  setState(() => _selectedItems.contains(item.id) ? _selectedItems.remove(item.id) : _selectedItems.add(item.id));
                                } else {
                                  final children = (menuState as MenuLoaded).items.where((i) => i.parentId == item.id).toList();
                                  final bool hasOptions = item.hasVariations || item.hasModifiers || children.isNotEmpty;
                                  if (hasOptions) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => MenuModifiersDialog(
                                        item: item,
                                        childrenItems: children.isNotEmpty ? children : null,
                                        isReadOnly: true,
                                      ),
                                    );
                                  } else {
                                    AppToast.showInfo(
                                      context,
                                      'У блюда нет опций',
                                    );
                                  }
                                }
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
