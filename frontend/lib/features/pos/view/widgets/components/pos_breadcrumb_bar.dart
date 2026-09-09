import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/pos/view/widgets/pos_settings_modal.dart';

class PosBreadcrumbBar extends StatelessWidget {
  final List<dynamic> history;
  final VoidCallback? onBack;
  final VoidCallback onRoot;
  final ValueChanged<int> onCrumb;
  final bool isSearching;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleSearch;
  final VoidCallback onClearSearch;
  final FocusNode? searchFocusNode;

  const PosBreadcrumbBar({
    super.key,
    required this.history,
    required this.onBack,
    required this.onRoot,
    required this.onCrumb,
    this.isSearching = false,
    this.searchQuery = '',
    required this.onSearchChanged,
    required this.onToggleSearch,
    required this.onClearSearch,
    this.searchFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: isSearching ? _buildSearchBar(context, isDark) : _buildNavRow(context, isDark),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Row(
      children: [
        Icon(PhosphorIconsRegular.magnifyingGlass, size: 18, color: AppColors.brandPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            focusNode: searchFocusNode,
            autofocus: true,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
            decoration: InputDecoration(
              hintText: 'Поиск блюда по названию или штрихкоду... (Esc для выхода)',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onSearchChanged,
          ),
        ),
        if (searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(PhosphorIconsRegular.xCircle, size: 18),
            color: AppColors.darkSubtext,
            onPressed: onClearSearch,
            tooltip: 'Очистить',
          ),
        IconButton(
          icon: const Icon(PhosphorIconsRegular.x, size: 18),
          color: AppColors.darkSubtext,
          onPressed: onToggleSearch,
          tooltip: 'Закрыть поиск (Esc)',
        ),
      ],
    );
  }

  Widget _buildNavRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        if (onBack != null)
          IconButton(
            icon: const Icon(PhosphorIconsRegular.caretLeft, size: 16),
            color: AppColors.darkSubtext,
            onPressed: onBack,
            tooltip: 'Назад',
          ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                GestureDetector(
                  onTap: onRoot,
                  child: Text(
                    'Меню',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: history.isEmpty ? AppColors.brandPrimary : AppColors.darkSubtext,
                    ),
                  ),
                ),
                for (int i = 0; i < history.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      PhosphorIconsRegular.caretRight,
                      size: 16,
                      color: AppColors.darkSubtext,
                    ),
                  ),
                  GestureDetector(
                    onTap: i == history.length - 1 ? null : () => onCrumb(i),
                    child: Text(
                      history[i].name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: i == history.length - 1 ? AppColors.brandPrimary : AppColors.darkSubtext,
                        fontWeight: i == history.length - 1 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 18),
          color: AppColors.darkSubtext,
          onPressed: onToggleSearch,
          tooltip: 'Поиск блюд (Ctrl+F)',
        ),
        IconButton(
          icon: const Icon(PhosphorIconsRegular.slidersHorizontal),
          color: AppColors.darkSubtext,
          onPressed: () => PosSettingsModal.show(context),
          tooltip: 'Настройки кассы',
        ),
      ],
    );
  }
}
