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
      'parent_id': parentId,
    };
  }

  String? getInheritedIcon(List<MenuCategory> allCategories) {
    if (icon != null && icon!.isNotEmpty) return icon;
    if (parentId != null) {
      try {
        final parent = allCategories.firstWhere((c) => c.id == parentId);
        final parentIcon = parent.getInheritedIcon(allCategories);
        if (parentIcon != null && parentIcon.isNotEmpty) return parentIcon;
      } catch (_) {}
    }
    return null;
  }
}
