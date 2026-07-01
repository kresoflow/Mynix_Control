 import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_event.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add_modal.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Widget _buildCategoryIcon(String name, {required double size, required Color color}) {
  final lower = name.toLowerCase();
  if (lower.contains('пицца')) return Icon(PhosphorIcons.pizza(), size: size, color: color);
  if (lower.contains('бургер')) return Icon(PhosphorIcons.hamburger(), size: size, color: color);
  if (lower.contains('напит') || lower.contains('вода') || lower.contains('сок')) return Center(child: FaIcon(FontAwesomeIcons.bottleWater, size: size, color: color));
  if (lower.contains('соус')) return Icon(PhosphorIcons.drop(), size: size, color: color);
  if (lower.contains('гарнир') || lower.contains('салат')) return Icon(PhosphorIcons.bowlFood(), size: size, color: color);
  if (lower.contains('десерт') || lower.contains('сладкое')) return Icon(PhosphorIcons.cookie(), size: size, color: color);
  if (lower.contains('хотдог')) return Center(child: FaIcon(FontAwesomeIcons.hotdog, size: size, color: color));
  return Icon(PhosphorIcons.package(), size: size, color: color);
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<_CategoryTabState> _categoryTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddMenuItemDialog(BuildContext context) {
    final catState = context.read<CategoryBloc>().state;
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    int? selectedCategoryId;

    if (catState is CategoryLoaded && catState.categories.isNotEmpty) {
      selectedCategoryId = catState.categories.first.id;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Новое блюдо'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Название блюда'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Цена (с)'),
                  ),
                  const SizedBox(height: 16),
                  if (catState is CategoryLoaded)
                    DropdownButtonFormField<int>(
                      initialValue: selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Категория'),
                      items: catState.categories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedCategoryId = val;
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final price = double.tryParse(priceController.text) ?? 0.0;
                    if (nameController.text.isNotEmpty && price > 0 && selectedCategoryId != null) {
                      context.read<MenuBloc>().add(
                            CreateMenuItem(
                              name: nameController.text,
                              price: price,
                              category: selectedCategoryId.toString(),
                            ),
                          );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddIngredientDialog(BuildContext context) {
    final nameController = TextEditingController();
    final costController = TextEditingController(text: '0');
    final alertController = TextEditingController(text: '0');
    String selectedUnit = 'g';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Новый ингредиент'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Название сырья'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      decoration: const InputDecoration(labelText: 'Единица измерения'),
                      items: const [
                        DropdownMenuItem(value: 'pcs', child: Text('Штуки (шт)')),
                        DropdownMenuItem(value: 'g', child: Text('Граммы (г)')),
                        DropdownMenuItem(value: 'kg', child: Text('Килограммы (кг)')),
                        DropdownMenuItem(value: 'ml', child: Text('Миллилитры (мл)')),
                        DropdownMenuItem(value: 'l', child: Text('Литры (л)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedUnit = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: costController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Себестоимость за ед. (с)'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: alertController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Минимальный остаток (алерт)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final cost = double.tryParse(costController.text) ?? 0.0;
                    final alert = double.tryParse(alertController.text) ?? 0.0;
                    if (nameController.text.isNotEmpty) {
                      context.read<IngredientBloc>().add(
                            CreateIngredient(
                              name: nameController.text,
                              unit: selectedUnit,
                              costPerUnit: cost,
                              minStockAlert: alert,
                            ),
                          );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleAddPressed() {
    switch (_tabController.index) {
      case 0:
        _categoryTabKey.currentState?._showAddDialog(context);
        break;
      case 1:
        _showAddMenuItemDialog(context);
        break;
      case 2:
        _showAddIngredientDialog(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).cardColor,
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(icon: Icon(Icons.category), text: 'Категории'),
                    Tab(icon: Icon(Icons.fastfood), text: 'Блюда'),
                    Tab(icon: Icon(Icons.kitchen), text: 'Ингредиенты'),
                    Tab(icon: Icon(Icons.receipt_long), text: 'Техкарты'),
                    Tab(icon: Icon(Icons.local_shipping), text: 'Приход'),
                  ],
                ),
              ),
              if (_tabController.index < 3)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const BulkAddModal(),
                          );
                        },
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('Массово'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _handleAddPressed,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _CategoryTab(key: _categoryTabKey),
              const _MenuTab(),
              const _IngredientTab(),
              const _RecipeTab(),
              const _ReceiptTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryTab extends StatefulWidget {
  const _CategoryTab({super.key});

  @override
  State<_CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends State<_CategoryTab> {
  List<dynamic> _navigationHistory = [];
  bool _isDeleteMode = false;
  Set<int> _selectedCategories = {};
  Set<int> _selectedItems = {};

  int? get _currentCategoryId =>
      _navigationHistory.isEmpty ? null : _navigationHistory.last.id;

  void _navigateUp() {
    if (_navigationHistory.isNotEmpty) {
      setState(() {
        _navigationHistory.removeLast();
      });
    }
  }

  void _navigateToRoot() {
    setState(() {
      _navigationHistory.clear();
    });
  }

  void _showAddDialog(BuildContext context) {
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
                  _showAddCategoryDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.fastfood),
                title: const Text('Добавить блюдо'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddMenuItemDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.storefront),
                title: const Text('Добавить товар (витрина)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddRetailProductDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final sortOrderController = TextEditingController(text: '0');
    bool isVisible = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
          title: const Text('Новая категория'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название категории'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sortOrderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Порядок сортировки'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Отображать на кассе'),
                value: isVisible,
                onChanged: (val) {
                  setState(() {
                    isVisible = val;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final sortOrder = int.tryParse(sortOrderController.text) ?? 0;
                if (nameController.text.isNotEmpty) {
                  context.read<CategoryBloc>().add(
                        CreateCategory(
                          name: nameController.text,
                          parentId: _currentCategoryId,
                          sortOrder: sortOrder,
                          isVisible: isVisible,
                        ),
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Создать'),
            ),
          ],
            );
          },
        );
      },
    );
  }

  void _showAddMenuItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Новое блюдо'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название блюда'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Цена (с)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final price = double.tryParse(priceController.text) ?? 0.0;
                if (nameController.text.isNotEmpty && price > 0) {
                  context.read<MenuBloc>().add(
                        CreateMenuItem(
                          name: nameController.text,
                          price: price,
                          category: _currentCategoryId?.toString() ?? '',
                        ),
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  void _showAddRetailProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    final flavorController = TextEditingController();
    final volumeController = TextEditingController();
    final purchasePriceController = TextEditingController();
    final sellingPriceController = TextEditingController();
    String selectedUnit = 'l';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Новый товар для витрины'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Название товара (Сникерс, Кола)'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: typeController,
                      decoration: const InputDecoration(labelText: 'Тип (опционально, напр: Черный, Классик)'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: flavorController,
                      decoration: const InputDecoration(labelText: 'Вкус (опционально, напр: Кола, Апельсин)'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: volumeController,
                      decoration: const InputDecoration(labelText: 'Объем / Вес (опционально, напр: 1л, 500г)'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      decoration: const InputDecoration(labelText: 'Единица измерения'),
                      items: const [
                        DropdownMenuItem(value: 'pcs', child: Text('Штуки (шт)')),
                        DropdownMenuItem(value: 'g', child: Text('Граммы (г)')),
                        DropdownMenuItem(value: 'kg', child: Text('Килограммы (кг)')),
                        DropdownMenuItem(value: 'ml', child: Text('Миллилитры (мл)')),
                        DropdownMenuItem(value: 'l', child: Text('Литры (л)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedUnit = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Цена закупки (с)'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: sellingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Цена продажи на кассе (с)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final pPrice = double.tryParse(purchasePriceController.text) ?? 0.0;
                    final sPrice = double.tryParse(sellingPriceController.text) ?? 0.0;
                    if (nameController.text.isNotEmpty && sPrice > 0) {
                      final Map<String, dynamic> attributes = {};
                      if (typeController.text.isNotEmpty) attributes['Тип'] = typeController.text;
                      if (flavorController.text.isNotEmpty) attributes['Вкус'] = flavorController.text;
                      if (volumeController.text.isNotEmpty) {
                        String uLabel = '';
                        if (selectedUnit == 'l') {
                          uLabel = 'л';
                        } else if (selectedUnit == 'ml') uLabel = 'мл';
                        else if (selectedUnit == 'kg') uLabel = 'кг';
                        else if (selectedUnit == 'g') uLabel = 'г';
                        else if (selectedUnit == 'pcs') uLabel = 'шт';
attributes['Объем'] = '${volumeController.text} $uLabel'.trim();
                      }

                      context.read<MenuBloc>().add(
                            CreateRetailProduct(
                              name: nameController.text,
                              categoryId: _currentCategoryId ?? 0,
                              unit: selectedUnit,
                              purchasePrice: pPrice,
                              sellingPrice: sPrice,
                              attributes: attributes.isNotEmpty ? attributes : null,
                            ),
                          );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<CategoryBloc, CategoryState>(
            listener: (context, state) {
              if (state is CategoryError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
              }
            },
          ),
          BlocListener<MenuBloc, MenuState>(
            listener: (context, state) {
              if (state is MenuError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.orange),
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
                  currentCategories = catState.categories
                      .where((c) => c.parentId == _currentCategoryId)
                      .toList();
                }

                List<dynamic> currentItems = [];
                if (menuState is MenuLoaded) {
                  currentItems = menuState.items.where((i) {
                    final itemCatId = int.tryParse(i.categoryId.toString());
                    return itemCatId == _currentCategoryId;
                  }).toList();
                }

                final int selectedCount = _selectedCategories.length + _selectedItems.length;
                final bool isAllSelected = currentCategories.isNotEmpty || currentItems.isNotEmpty
                    ? selectedCount == (currentCategories.length + currentItems.length)
                    : false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _isDeleteMode
                            ? Theme.of(context).colorScheme.errorContainer
                            : Theme.of(context).cardColor,
                        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                      ),
                      child: _isDeleteMode
                          ? Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _isDeleteMode = false;
                                      _selectedCategories.clear();
                                      _selectedItems.clear();
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Выбрано: $selectedCount',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                TextButton.icon(
                                  icon: Icon(isAllSelected ? Icons.deselect : Icons.select_all),
                                  label: Text(isAllSelected ? 'Снять выделение' : 'Выбрать все'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                                  onPressed: () {
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
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.delete_forever),
                                  label: const Text('Удалить'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: selectedCount == 0 ? null : () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Массовое удаление'),
                                        content: Text('Удалить выбранные элементы ($selectedCount шт.)?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Отмена'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
                                                _isDeleteMode = false;
                                              });
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text('Удалить'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                if (_navigationHistory.isNotEmpty) ...[
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: _navigateUp,
                                    tooltip: 'Назад',
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        InkWell(
                                          onTap: _navigateToRoot,
                                          child: const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text('Все категории', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        ...List.generate(_navigationHistory.length, (index) {
                                          final cat = _navigationHistory[index];
                                          final isLast = index == _navigationHistory.length - 1;
                                          return Row(
                                            children: [
                                              const Icon(Icons.chevron_right, color: Colors.grey),
                                              InkWell(
                                                onTap: isLast
                                                    ? null
                                                    : () {
                                                        setState(() {
                                                          _navigationHistory =
                                                              _navigationHistory.sublist(0, index + 1);
                                                        });
                                                      },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    cat.name,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                                                      color: isLast ? colorScheme.primary : null,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Выбрать для удаления',
                                  onPressed: () {
                                    setState(() {
                                      _isDeleteMode = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (currentCategories.isEmpty && currentItems.isEmpty) {
                            return const Center(child: Text('Здесь пока пусто. Нажмите "Добавить", чтобы создать подкатегорию или блюдо.'));
                          }

                          final totalItems = currentCategories.length + currentItems.length;

                          return GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200,
                              childAspectRatio: 1.0,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: totalItems,
                            itemBuilder: (context, index) {
                              if (index < currentCategories.length) {
                                // Render Category Card
                                final cat = currentCategories[index];
                                return AppCard(
                                  onTap: () {
                                    if (_isDeleteMode) {
                                      setState(() {
                                        if (_selectedCategories.contains(cat.id)) {
                                          _selectedCategories.remove(cat.id);
                                        } else {
                                          _selectedCategories.add(cat.id);
                                        }
                                      });
                                    } else {
                                      setState(() {
                                        _navigationHistory.add(cat);
                                      });
                                    }
                                  },
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Container(
                                              width: 56,
                                              height: 56,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: AppColors.brandPrimary.withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: _buildCategoryIcon(
                                                cat.name,
                                                size: 32,
                                                color: AppColors.brandPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            Text(
                                              cat.name,
                                              style: AppTextStyles.h3.copyWith(
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? AppColors.darkText
                                                    : AppColors.lightText,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_isDeleteMode)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Checkbox(
                                            value: _selectedCategories.contains(cat.id),
                                            onChanged: (val) {
                                              setState(() {
                                                if (val == true) {
                                                  _selectedCategories.add(cat.id);
                                                } else {
                                                  _selectedCategories.remove(cat.id);
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              } else {
                                // Render Menu Item Card
                                final item = currentItems[index - currentCategories.length];
                                return AppCard(
                                  onTap: () {
                                    if (_isDeleteMode) {
                                      setState(() {
                                        if (_selectedItems.contains(item.id)) {
                                          _selectedItems.remove(item.id);
                                        } else {
                                          _selectedItems.add(item.id);
                                        }
                                      });
                                    } else {
                                      // TODO: Open item edit dialog
                                    }
                                  },
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Container(
                                              width: 52,
                                              height: 52,
                                              decoration: BoxDecoration(
                                                color: AppColors.brandPrimary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Icon(
                                                PhosphorIcons.hamburger(),
                                                size: 26,
                                                color: AppColors.brandPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              item.cleanName,
                                              style: AppTextStyles.h3.copyWith(
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? AppColors.darkText
                                                    : AppColors.lightText,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (item.attributesString != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                item.attributesString!,
                                                style: AppTextStyles.caption,
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            const SizedBox(height: 10),
                                            Align(
                                              alignment: Alignment.center,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).brightness == Brightness.dark 
                                                      ? AppColors.darkBg 
                                                      : AppColors.lightBg,
                                                  borderRadius: BorderRadius.circular(100),
                                                  border: Border.all(
                                                      color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                                                ),
                                                child: Text(
                                                  '${item.price.toInt()} с',
                                                  style: GoogleFonts.jetBrainsMono(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.brandPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_isDeleteMode)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Checkbox(
                                            value: _selectedItems.contains(item.id),
                                            onChanged: (val) {
                                              setState(() {
                                                if (val == true) {
                                                  _selectedItems.add(item.id);
                                                } else {
                                                  _selectedItems.remove(item.id);
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }
                            },
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

class _MenuTab extends StatelessWidget {
  const _MenuTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, catState) {
        return Scaffold(
          body: BlocBuilder<MenuBloc, MenuState>(
            builder: (context, state) {
              if (state is MenuLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is MenuLoaded) {
                final dishes = state.items.where((i) => !i.isRetail).toList();
                
                if (dishes.isEmpty) {
                  return const Center(child: Text('Нет блюд'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: dishes.length,
                  itemBuilder: (context, index) {
                    final item = dishes[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(item.cleanName),
                        subtitle: Text('${item.price} с'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            context.read<MenuBloc>().add(DeleteMenuItem(item.id));
                          },
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(child: Text('Ошибка загрузки блюд'));
            },
          ),
        );
      },
    );
  }
}

class _IngredientTab extends StatelessWidget {
  const _IngredientTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<IngredientBloc, IngredientState>(
        builder: (context, state) {
          if (state is IngredientLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is IngredientLoaded) {
            if (state.ingredients.isEmpty) {
              return const Center(child: Text('Нет ингредиентов на складе'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: state.ingredients.length,
              itemBuilder: (context, index) {
                final item = state.ingredients[index];
                final isLowStock = item.isLowStock;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isLowStock ? Colors.red.withValues(alpha: 0.2) : Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.kitchen,
                        color: isLowStock ? Colors.red : Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    title: Text(item.name),
                    subtitle: Text('Остаток: ${item.currentStock} ${item.unit} | Мин: ${item.minStockAlert} ${item.unit}'),
                    trailing: Text(
                      '${item.costPerUnit} с / ${item.unit}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Ошибка загрузки склада'));
        },
      ),
    );
  }
}

class _RecipeTab extends StatefulWidget {
  const _RecipeTab();

  @override
  State<_RecipeTab> createState() => _RecipeTabState();
}

class _RecipeTabState extends State<_RecipeTab> {
  int? _selectedMenuItemId;

  void _showAddIngredientToRecipeDialog(BuildContext context, int menuItemId, List<dynamic> ingredients) {
    int? selectedIngredientId;
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Добавить ингредиент в техкарту'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedIngredientId,
                    decoration: const InputDecoration(labelText: 'Сырье'),
                    items: ingredients.map((ing) {
                      return DropdownMenuItem<int>(
                        value: ing.id,
                        child: Text('${ing.name} (${ing.unit})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedIngredientId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Количество по норме'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final qty = double.tryParse(qtyController.text) ?? 0;
                    if (selectedIngredientId != null && qty > 0) {
                      context.read<RecipeBloc>().add(
                            AddIngredientToRecipe(
                              menuItemId: menuItemId,
                              ingredientId: selectedIngredientId!,
                              quantity: qty,
                            ),
                          );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Настройка технологических карт',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left list: Menu Items
                Expanded(
                  flex: 1,
                  child: BlocBuilder<MenuBloc, MenuState>(
                    builder: (context, state) {
                      if (state is MenuLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is MenuLoaded) {
                        if (state.items.isEmpty) {
                          return const Center(child: Text('Нет блюд в меню'));
                        }
                        return ListView.builder(
                          itemCount: state.items.length,
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            final isSelected = _selectedMenuItemId == item.id;
                            return Card(
                              color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                              child: ListTile(
                                title: Text(item.name),
                                onTap: () {
                                  setState(() {
                                    _selectedMenuItemId = item.id;
                                  });
                                  context.read<RecipeBloc>().add(LoadRecipe(item.id));
                                },
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                const SizedBox(width: 24),
                // Right panel: Recipe details
                Expanded(
                  flex: 2,
                  child: _selectedMenuItemId == null
                      ? const Center(
                          child: Text(
                            'Выберите блюдо для редактирования техкарты',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : BlocBuilder<RecipeBloc, RecipeState>(
                          builder: (context, state) {
                            if (state is RecipeLoading) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (state is RecipeLoaded && state.menuItemId == _selectedMenuItemId) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Ингредиенты (${state.recipes.length})',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                      BlocBuilder<IngredientBloc, IngredientState>(
                                        builder: (context, ingState) {
                                          return ElevatedButton.icon(
                                            onPressed: () {
                                              if (ingState is IngredientLoaded) {
                                                _showAddIngredientToRecipeDialog(
                                                    context, _selectedMenuItemId!, ingState.ingredients);
                                              }
                                            },
                                            icon: const Icon(Icons.add),
                                            label: const Text('Добавить'),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (state.recipes.isEmpty)
                                    const Center(child: Text('В техкарте пока нет ингредиентов.')),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: state.recipes.length,
                                      itemBuilder: (context, index) {
                                        final recipe = state.recipes[index];
                                        return Card(
                                          child: ListTile(
                                            title: Text(recipe['ingredient_name'] ?? 'Unknown'),
                                            subtitle: Text('Расход: ${recipe['quantity_required']} ед.'),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () {
                                                context.read<RecipeBloc>().add(
                                                  RemoveIngredientFromRecipe(
                                                    menuItemId: _selectedMenuItemId!,
                                                    ingredientId: recipe['ingredient_id'],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const Center(child: Text('Загрузка техкарты...'));
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptTab extends StatelessWidget {
  const _ReceiptTab();

  void _showReceiveStockDialog(BuildContext context, int ingredientId, String ingredientName, String unit) {
    final qtyController = TextEditingController();
    final reasonController = TextEditingController(text: 'Приёмка товара');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Оформить приход: $ingredientName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Количество ($unit)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Причина / Комментарий'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final qty = double.tryParse(qtyController.text) ?? 0;
                if (qty > 0) {
                  context.read<IngredientBloc>().add(
                    ReceiveStock(
                      ingredientId: ingredientId,
                      quantity: qty,
                      reason: reasonController.text,
                    ),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Приход сырья на склад',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BlocBuilder<IngredientBloc, IngredientState>(
              builder: (context, state) {
                if (state is IngredientLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is IngredientLoaded) {
                  if (state.ingredients.isEmpty) {
                    return const Center(child: Text('Нет сырья для прихода. Сначала добавьте ингредиенты.'));
                  }
                  return ListView.builder(
                    itemCount: state.ingredients.length,
                    itemBuilder: (context, index) {
                      final item = state.ingredients[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.add_shopping_cart)),
                          title: Text(item.name),
                          subtitle: Text('Текущий остаток: ${item.currentStock} ${item.unit}'),
                          trailing: ElevatedButton(
                            onPressed: () => _showReceiveStockDialog(context, item.id, item.name, item.unit),
                            child: const Text('Оформить приход'),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: Text('Ошибка загрузки'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
