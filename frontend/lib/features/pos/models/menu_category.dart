class MenuCategory {
  final int id;
  final String name;
  final String categoryType;
  final int sortOrder;
  final String? color;
  final String? icon;
  final int level;
  final String? path;
  final bool isVisible;
  final bool isArchived;
  final int? parentId;

  MenuCategory({
    required this.id,
    required this.name,
    this.categoryType = 'dish',
    required this.sortOrder,
    this.color,
    this.icon,
    this.level = 1,
    this.path,
    this.isVisible = true,
    this.isArchived = false,
    this.parentId,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      categoryType: json['category_type'] as String? ?? 'dish',
      sortOrder: json['sort_order'] as int? ?? 0,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      level: json['level'] as int? ?? 1,
      path: json['path'] as String?,
      isVisible: json['is_visible'] as bool? ?? true,
      isArchived: json['is_archived'] as bool? ?? false,
      parentId: json['parent_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_type': categoryType,
      'sort_order': sortOrder,
      'color': color,
      'icon': icon,
      'level': level,
      'path': path,
      'is_visible': isVisible,
      'is_archived': isArchived,
      'parent_id': parentId,
    };
  }

  String? getInheritedIcon(List<MenuCategory> allCategories) {
    if (icon != null && icon!.isNotEmpty) {
      final cleanIcon = icon!.replaceAll('icon:', '').trim();
      if (cleanIcon.isNotEmpty && cleanIcon != 'null' && cleanIcon != 'none' && cleanIcon != 'undefined') {
        return icon;
      }
    }
    if (parentId != null) {
      try {
        final parent = allCategories.firstWhere((c) => c.id == parentId);
        final parentIcon = parent.getInheritedIcon(allCategories);
        if (parentIcon != null && parentIcon.isNotEmpty) return parentIcon;
      } catch (_) {}
    }
    return null;
  }

  String? getInheritedColor(List<MenuCategory> allCategories) {
    if (color != null && color!.trim().isNotEmpty && color != 'null' && color != 'none') {
      return color;
    }
    if (parentId != null) {
      try {
        final parent = allCategories.firstWhere((c) => c.id == parentId);
        final parentColor = parent.getInheritedColor(allCategories);
        if (parentColor != null && parentColor.isNotEmpty) return parentColor;
      } catch (_) {}
    }
    return null;
  }
}
