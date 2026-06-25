import 'package:flutter/material.dart';
import 'package:retail_os_frontend/features/pos/models/menu_item.dart';
import '../catalog_enums.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MenuListItem extends StatelessWidget {
  final MenuItem item;
  final CategoryManageMode manageMode;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool?> onToggleSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MenuListItem({
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(PhosphorIconsRegular.hamburger, color: Colors.grey),
        title: Text(item.cleanName, style: const TextStyle(fontSize: 16)),
        subtitle: item.attributesString != null ? Text(item.attributesString!) : null,
        trailing: manageMode == CategoryManageMode.delete
            ? Checkbox(value: isSelected, onChanged: onToggleSelect)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${item.price.toInt()} с', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  PopupMenuButton<String>(
                    icon: const Icon(PhosphorIconsRegular.dotsThreeVertical, color: Colors.grey),
                    onSelected: (val) {
                      if (val == 'edit') onEdit();
                      else if (val == 'delete') onDelete();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                      const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
        onTap: onTap,
      ),
    );
  }
}
