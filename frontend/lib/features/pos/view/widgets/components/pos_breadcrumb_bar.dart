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
  final bool isSearchOpen;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;

  const PosBreadcrumbBar({
    super.key,
    required this.history,
    required this.onBack,
    required this.onRoot,
    required this.onCrumb,
    required this.isSearchOpen,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
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
      child: Row(
        children: [
          // ── Breadcrumbs ──────────────────────────────────────────────
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
          const SizedBox(width: 12),

          // ── Search Mode (Collapsible Input Box or Simple IconButton) ──
          if (isSearchOpen)
            _buildExpandedSearchBox(context, isDark, border)
          else
            IconButton(
              icon: const Icon(PhosphorIconsRegular.magnifyingGlass),
              color: AppColors.darkSubtext,
              onPressed: onOpenSearch,
              tooltip: 'Поиск блюд (Ctrl+F)',
            ),
          const SizedBox(width: 4),

          // ── POS Settings Button ─────────────────────────────────────
          IconButton(
            icon: const Icon(PhosphorIconsRegular.slidersHorizontal),
            color: AppColors.darkSubtext,
            onPressed: () => PosSettingsModal.show(context),
            tooltip: 'Настройки кассы',
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedSearchBox(BuildContext context, bool isDark, Color border) {
    return Container(
      width: 280,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.brandPrimary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(PhosphorIconsRegular.magnifyingGlass, size: 15, color: AppColors.brandPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              autofocus: true,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              decoration: InputDecoration(
                hintText: 'Поиск блюд... (Esc для сброса)',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          InkWell(
            onTap: onCloseSearch,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(
                PhosphorIconsRegular.xCircle,
                size: 16,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
