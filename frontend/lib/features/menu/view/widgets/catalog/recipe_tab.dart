import 'package:flutter/material.dart';
import 'recipe_menu_list.dart';
import 'recipe_details_panel.dart';

class RecipeTab extends StatefulWidget {
  const RecipeTab({super.key});

  @override
  State<RecipeTab> createState() => RecipeTabState();
}

class RecipeTabState extends State<RecipeTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  int? _selectedMenuItemId;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                Expanded(
                  flex: 1,
                  child: RecipeMenuList(
                    selectedMenuItemId: _selectedMenuItemId,
                    onMenuItemSelected: (id) {
                      setState(() {
                        _selectedMenuItemId = id;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: _selectedMenuItemId == null
                      ? const Center(
                          child: Text(
                            'Выберите блюдо для редактирования техкарты',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : RecipeDetailsPanel(selectedMenuItemId: _selectedMenuItemId!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
