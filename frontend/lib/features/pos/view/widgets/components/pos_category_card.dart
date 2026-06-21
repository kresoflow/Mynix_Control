import 'package:flutter/material.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import 'package:retail_os_frontend/core/theme/app_text_styles.dart';
import 'package:retail_os_frontend/core/widgets/app_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Widget _buildCategoryIcon(String name, {required double size, required Color color}) {
  final lower = name.toLowerCase();
  if (lower.contains('пицца')) return Icon(PhosphorIcons.pizza(), size: size, color: color);
  if (lower.contains('бургер')) return Icon(PhosphorIcons.hamburger(), size: size, color: color);
  if (lower.contains('напит') || lower.contains('вода') || lower.contains('сок')) return Center(child: FaIcon(FontAwesomeIcons.bottleWater, size: size, color: color));
  if (lower.contains('соус')) return Icon(PhosphorIcons.drop(), size: size, color: color);
  if (lower.contains('гарнир') || lower.contains('салат')) return Icon(PhosphorIcons.bowlFood(), size: size, color: color);
  if (lower.contains('десерт') || lower.contains('сладкое')) return Icon(PhosphorIcons.cookie(), size: size, color: color);
  if (lower.contains('хотдог')) return Center(child: FaIcon(FontAwesomeIcons.hotdog, size: size, color: color));
  return Icon(PhosphorIcons.package(), size: size, color: color);
}

class PosCategoryCard extends StatelessWidget {
  final dynamic cat;
  final Color accent;
  final VoidCallback onTap;

  const PosCategoryCard({
    super.key,
    required this.cat,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent, accent.withValues(alpha: 0.6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildCategoryIcon(
                cat.name,
                size: 32, 
                color: Colors.white
              ),
            ),
            Text(
              cat.name,
              style: AppTextStyles.h3.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkText
                    : AppColors.lightText,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
