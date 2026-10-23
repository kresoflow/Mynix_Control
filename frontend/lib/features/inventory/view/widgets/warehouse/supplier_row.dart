// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/main_layout/icon_btn.dart';
import 'package:kreso_frontend/features/inventory/models/supplier.dart';

// ==============================================================================
// 2. СТРОКА ТАБЛИЦЫ ПОСТАВЩИКОВ
// ==============================================================================
/// [ИНВАРИАНТ] Строка отображения данных контрагента с балансом взаиморасчетов.
class SupplierRow extends StatefulWidget {
  final Supplier supplier;
  final String currency;
  final bool isLast;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;
  final VoidCallback onPayDebt;
  final VoidCallback onOpenSettlement;

  const SupplierRow({
    super.key,
    required this.supplier,
    required this.currency,
    required this.isLast,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    required this.onPayDebt,
    required this.onOpenSettlement,
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
      child: InkWell(
        onTap: widget.onOpenSettlement,
        borderRadius: widget.isLast ? const BorderRadius.vertical(bottom: Radius.circular(12)) : null,
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
                  style: AppTextStyles.caption.copyWith(
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
                        color: AppColors.brandPrimary.withValues(alpha: 0.12),
                        borderRadius: AppRadii.inputRadius,
                      ),
                      child: Center(
                        child: Text(
                          s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                          style: AppTextStyles.bodyMedium.copyWith(
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
                        style: AppTextStyles.bodyMedium.copyWith(
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
                flex: 2,
                child: Text(
                  (s.contactInfo ?? '').isNotEmpty ? s.contactInfo! : '—',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: (s.contactInfo ?? '').isNotEmpty
                        ? (widget.isDark ? AppColors.darkText : AppColors.lightText)
                        : (widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // ── Баланс взаиморасчетов ─────────────────────────────────
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: widget.onOpenSettlement,
                    borderRadius: AppRadii.inputRadius,
                    child: _buildBalanceBadge(s.balance, widget.currency, widget.isDark),
                  ),
                ),
              ),

              // ── Статус ────────────────────────────────────────────────
              SizedBox(
                width: 90,
                child: InkWell(
                  onTap: widget.onToggleActive,
                  borderRadius: AppRadii.radiusPill,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: s.isActive
                          ? AppColors.success.withValues(alpha: 0.1)
                          : (widget.isDark ? AppColors.darkBg : AppColors.lightBg),
                      borderRadius: AppRadii.radiusPill,
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
                          style: AppTextStyles.caption.copyWith(
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

              // ── Действия ──────────────────────────────────────────────
              SizedBox(
                width: 130,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconBtn(
                      icon: PhosphorIconsRegular.wallet,
                      tooltip: 'Взаиморасчёты и долги',
                      color: AppColors.brandPrimary,
                      onPressed: widget.onOpenSettlement,
                    ),
                    const SizedBox(width: 2),
                    IconBtn(
                      icon: PhosphorIconsRegular.pencilSimple,
                      tooltip: 'Редактировать',
                      color: AppColors.darkSubtext,
                      onPressed: widget.onEdit,
                    ),
                    const SizedBox(width: 2),
                    IconBtn(
                      icon: PhosphorIconsRegular.trash,
                      tooltip: 'Удалить',
                      color: AppColors.danger,
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceBadge(double balance, String currency, bool isDark) {
    if (balance < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: AppRadii.inputRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(PhosphorIconsRegular.warningCircle, size: 13, color: AppColors.danger),
            const SizedBox(width: 4),
            Text(
              'Долг: ${balance.abs().toStringAsFixed(2)} $currency',
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      );
    } else if (balance > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: AppRadii.inputRadius,
        ),
        child: Text(
          '+${balance.toStringAsFixed(2)} $currency (Аванс)',
          style: AppTextStyles.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
      );
    }
    return Text(
      '0.00 $currency',
      style: AppTextStyles.caption.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
      ),
    );
  }
}
