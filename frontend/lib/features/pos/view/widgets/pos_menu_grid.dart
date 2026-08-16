import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_nav_cubit.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_settings_cubit.dart';
import 'package:mynix_frontend/features/pos/view/widgets/components/pos_breadcrumb_bar.dart';
import 'package:mynix_frontend/features/pos/view/widgets/components/pos_empty_state.dart';
import 'package:mynix_frontend/features/pos/view/widgets/components/pos_menu_grid_view.dart';

class PosMenuGrid extends StatelessWidget {
  const PosMenuGrid({super.key});

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
              Expanded(
                child: BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, catState) {
                    return BlocBuilder<MenuBloc, MenuState>(
                      builder: (context, menuState) {
                        if (catState is CategoryLoading || menuState is MenuLoading) {
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
                          return PosEmptyState(inCategory: currentCategoryId != null);
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
