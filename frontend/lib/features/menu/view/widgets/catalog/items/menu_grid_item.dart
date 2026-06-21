import 'package:flutter/material.dart';
import 'package:retail_os_frontend/features/pos/models/menu_item.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import 'package:retail_os_frontend/core/theme/app_text_styles.dart';
import 'package:retail_os_frontend/core/widgets/app_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../catalog_enums.dart';

class MenuGridItem extends StatelessWidget {
  final MenuItem item;
  final CategoryManageMode manageMode;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool?> onToggleSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MenuGridItem({
    super.key,
    required this.item,
    required this.manageMode,
    required this.isSelected,
    required this.onTap,
    required this.onToggleSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
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
                  child: Icon(PhosphorIcons.hamburger(), size: 26, color: AppColors.brandPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  item.cleanName,
                  style: AppTextStyles.h3.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.attributesString != null) ...[
                  const SizedBox(height: 4),
                  Text(item.attributesString!, style: AppTextStyles.caption, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBg : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${item.price.toInt()} с',
                      style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (manageMode == CategoryManageMode.delete)
            Positioned(top: 4, right: 4, child: Checkbox(value: isSelected, onChanged: onToggleSelect))
          else if (manageMode == CategoryManageMode.none)
            Positioned(
              top: 0,
              right: 0,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  else if (val == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                  const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
