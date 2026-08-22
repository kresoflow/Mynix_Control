import 'package:flutter/material.dart';
import 'recipe_menu_list.dart';
import 'recipe_details_panel.dart';
import 'recipe/recipe_empty_dashboard.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

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
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Настройка технологических карт',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: RecipeMenuList(
                    selectedMenuItemId: _selectedMenuItemId,
                    onMenuItemSelected: (id) {
                      setState(() {
                        _selectedMenuItemId = id;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _selectedMenuItemId == null
                      ? RecipeEmptyDashboard(
                          onSelectDish: (id) {
                            setState(() {
                              _selectedMenuItemId = id;
                            });
                          },
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
