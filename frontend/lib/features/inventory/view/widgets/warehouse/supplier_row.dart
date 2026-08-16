import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/inventory/models/supplier.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SupplierRow extends StatefulWidget {
  final Supplier supplier;
  final bool isLast;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const SupplierRow({
    super.key,
    required this.supplier,
    required this.isLast,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  State<SupplierRow> createState() => _SupplierRowState();
}

class _SupplierRowState extends State<SupplierRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.supplier;
    final rowBg = _isHovered
        ? (widget.isDark ? AppColors.darkCardHover : AppColors.lightCardHover)
        : (widget.isDark ? AppColors.darkCard : AppColors.lightCard);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: rowBg,
          borderRadius: widget.isLast ? const BorderRadius.vertical(bottom: Radius.circular(12)) : null,
          border: Border(
            left: BorderSide(color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
            right: BorderSide(color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
            bottom: BorderSide(color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                '#${s.id}',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: s.isActive
                            ? (widget.isDark ? AppColors.darkText : AppColors.lightText)
                            : (widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                        decoration: s.isActive ? null : TextDecoration.lineThrough,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                (s.contactInfo ?? '').isNotEmpty ? s.contactInfo! : '—',
                style: TextStyle(
                  fontSize: 13,
                  color: (s.contactInfo ?? '').isNotEmpty
                      ? (widget.isDark ? AppColors.darkText : AppColors.lightText)
                      : (widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 90,
              child: InkWell(
                onTap: widget.onToggleActive,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: s.isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.darkSubtext.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s.isActive ? AppColors.success : AppColors.darkSubtext,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        s.isActive ? 'Активен' : 'Неактивен',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: s.isActive ? AppColors.success : AppColors.darkSubtext,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(PhosphorIconsRegular.pencilSimple, size: 16, color: AppColors.brandPrimary),
                    tooltip: 'Редактировать',
                    onPressed: widget.onEdit,
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.danger),
                    tooltip: 'Удалить',
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
