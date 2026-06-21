import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_event.dart';
import 'package:retail_os_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:retail_os_frontend/features/pos/models/menu_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'catalog_dialogs.dart';
import 'catalog_header.dart';
import 'catalog_content_view.dart';
import 'catalog_enums.dart';

class CatalogBrowserTab extends StatefulWidget {
  final String categoryType;
  final bool Function(MenuItem) itemFilter;
  final Widget Function(BuildContext context, int? categoryId)? addMenuBuilder;
  final String emptyMessage;

  const CatalogBrowserTab({
    super.key,
    required this.categoryType,
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
                leading: const Icon(Icons.category),
                title: const Text('Создать подкатегорию'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddCategoryDialog(context, currentCategoryId: _currentCategoryId, type: parentType);
                },
              ),
              ListTile(
                leading: const Icon(Icons.fastfood),
                title: const Text('Добавить блюдо'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddMenuItemDialog(context, currentCategoryId: _currentCategoryId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.storefront),
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
              if (state is CategoryError) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
            },
          ),
          BlocListener<MenuBloc, MenuState>(
            listener: (context, state) {
              if (state is MenuError) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.orange));
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
                      .where((c) => c.parentId == _currentCategoryId && (widget.categoryType == 'all' || c.categoryType == widget.categoryType))
                      .toList();
                }

                List<dynamic> currentItems = [];
                if (menuState is MenuLoaded) {
                  final currentCatStr = _currentCategoryId?.toString();
                  currentItems = menuState.items.where((i) {
                    final iCatStr = i.categoryId.toString();
                    final isRootItem = iCatStr == '0' || iCatStr == 'null' || iCatStr == 'uncategorized' || iCatStr == '';
                    final inCategory = iCatStr == currentCatStr || (isRootItem && currentCatStr == null);
                    return inCategory && widget.itemFilter(i);
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
                          builder: (ctx) => AlertDialog(
                            title: const Text('Массовое удаление'),
                            content: Text('Удалить выбранные элементы ($selectedCount шт.)?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                onPressed: () {
                                  for (var itemId in _selectedItems) context.read<MenuBloc>().add(DeleteMenuItem(itemId));
                                  for (var catId in _selectedCategories) context.read<CategoryBloc>().add(DeleteCategory(catId, mode: 'all'));
                                  setState(() {
                                    _selectedItems.clear();
                                    _selectedCategories.clear();
                                    _manageMode = CategoryManageMode.none;
                                  });
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Удалить'),
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
                          if (isLoading) return const Center(child: CircularProgressIndicator());
                          
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
                            onItemTap: (item) {
                              if (_manageMode == CategoryManageMode.delete) {
                                setState(() => _selectedItems.contains(item.id) ? _selectedItems.remove(item.id) : _selectedItems.add(item.id));
                              }
                            },
                            onItemToggle: (item, val) => setState(() => val == true ? _selectedItems.add(item.id) : _selectedItems.remove(item.id)),
                            onItemEdit: (item) => showAddMenuItemDialog(context, itemToEdit: item),
                            onItemDelete: (item) => context.read<MenuBloc>().add(DeleteMenuItem(item.id)),
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
