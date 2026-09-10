import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class CatalogBreadcrumbs extends StatelessWidget {
  final String rootTitle;
  final List<dynamic> navigationHistory;
  final bool isMobile;
  final VoidCallback onNavigateToRoot;
  final ValueChanged<int> onNavigateToHistory;

  const CatalogBreadcrumbs({
    super.key,
    required this.rootTitle,
    required this.navigationHistory,
    required this.isMobile,
    required this.onNavigateToRoot,
    required this.onNavigateToHistory,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> crumbs = [];
    crumbs.add(
      InkWell(
        onTap: onNavigateToRoot,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            rootTitle,
            style: isMobile ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold) : AppTextStyles.h2,
          ),
        ),
      ),
    );

    for (int i = 0; i < navigationHistory.length; i++) {
      final isLast = i == navigationHistory.length - 1;
      final category = navigationHistory[i];
      crumbs.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            PhosphorIconsRegular.caretRight,
            size: isMobile ? 14 : 18,
            color: Theme.of(context).disabledColor,
          ),
        ),
      );
      crumbs.add(
        InkWell(
          onTap: isLast ? null : () => onNavigateToHistory(i),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              category.name,
              style: isLast
                  ? (isMobile ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold) : AppTextStyles.h2)
                  : (isMobile ? AppTextStyles.caption : AppTextStyles.bodyMedium)
                      .copyWith(color: Theme.of(context).disabledColor),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: crumbs),
    );
  }
}
