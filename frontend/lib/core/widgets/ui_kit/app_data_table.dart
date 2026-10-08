// ==============================================================================
// МОДУЛЬ: Ядро дизайн-системы / Стандартизированная таблица данных
// ДОМЕН: lib/core/widgets/ui_kit/app_data_table.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_motion.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

/// Модель конфигурации колонки таблицы
class AppDataTableColumn {
  final String label;
  final int flex;
  final double? width;
  final Alignment alignment;
  final bool isSortable;
  final bool? sortAscending;
  final VoidCallback? onSort;

  const AppDataTableColumn({
    required this.label,
    this.flex = 1,
    this.width,
    this.alignment = Alignment.centerLeft,
    this.isSortable = false,
    this.sortAscending,
    this.onSort,
  });
}

/// Стандартизированная шапка таблицы (Data Table Header) в стиле Stripe & Linear.
class AppDataTableHeader extends StatelessWidget {
  final List<AppDataTableColumn> columns;
  final double horizontalPadding;
  final double height;

  const AppDataTableHeader({
    super.key,
    required this.columns,
    this.horizontalPadding = 16,
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightBg,
        border: Border.symmetric(
          horizontal: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: columns.map((col) => _buildColumnCell(col, subtextColor)).toList(),
      ),
    );
  }

  Widget _buildColumnCell(AppDataTableColumn col, Color subtextColor) {
    final textWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          col.label.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.6,
            color: subtextColor,
          ),
        ),
        if (col.isSortable) ...[
          const SizedBox(width: 4),
          Icon(
            col.sortAscending == null
                ? PhosphorIconsRegular.arrowsDownUp
                : (col.sortAscending! ? PhosphorIconsRegular.arrowUp : PhosphorIconsRegular.arrowDown),
            size: 12,
            color: col.sortAscending != null ? AppColors.brandPrimary : subtextColor,
          ),
        ],
      ],
    );

    Widget aligned = Align(alignment: col.alignment, child: textWidget);

    if (col.isSortable && col.onSort != null) {
      aligned = InkWell(
        onTap: col.onSort,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: aligned,
        ),
      );
    }

    if (col.width != null) {
      return SizedBox(width: col.width, child: aligned);
    }
    return Expanded(flex: col.flex, child: aligned);
  }
}

/// Стандартизированная интерактивная строка таблицы (Data Table Row).
class AppDataTableRow extends StatefulWidget {
  final List<Widget> children;
  final List<AppDataTableColumn> columns;
  final double horizontalPadding;
  final double minHeight;
  final bool isHoverable;
  final bool isSelected;
  final VoidCallback? onTap;

  const AppDataTableRow({
    super.key,
    required this.children,
    required this.columns,
    this.horizontalPadding = 16,
    this.minHeight = 48,
    this.isHoverable = true,
    this.isSelected = false,
    this.onTap,
  }) : assert(children.length == columns.length, 'Количество ячеек должно совпадать с количеством колонок');

  @override
  State<AppDataTableRow> createState() => _AppDataTableRowState();
}

class _AppDataTableRowState extends State<AppDataTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    if (widget.isSelected) {
      bg = AppColors.brandPrimary.withValues(alpha: isDark ? 0.16 : 0.10);
    } else if (_isHovered && widget.isHoverable) {
      bg = isDark ? AppColors.darkCardHover : AppColors.lightBg;
    } else {
      bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    }

    return MouseRegion(
      onEnter: widget.isHoverable ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.isHoverable ? (_) => setState(() => _isHovered = false) : null,
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standardCurve,
          constraints: BoxConstraints(minHeight: widget.minHeight),
          padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < widget.children.length; i++)
                _buildCell(widget.columns[i], widget.children[i]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(AppDataTableColumn col, Widget child) {
    final aligned = Align(alignment: col.alignment, child: child);
    if (col.width != null) {
      return SizedBox(width: col.width, child: aligned);
    }
    return Expanded(flex: col.flex, child: aligned);
  }
}
