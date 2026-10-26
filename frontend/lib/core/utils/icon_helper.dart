import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IconHelper {
  static final Map<String, dynamic> _iconMap = {
    // Custom SVGs
    'svg:burger': 'svg:burger',
    'svg:hotdog': 'svg:hotdog',
    'svg:shawarma': 'svg:shawarma',
    'svg:pizza': 'svg:pizza',
    'svg:side_dish': 'svg:side_dish',
    'svg:sauces': 'svg:sauces',
    'svg:drinks': 'svg:drinks',
    'svg:ice_cream': 'svg:ice_cream',
    
    // Default fallback (can be used as a string constant to let buildIcon handle it)
    'ph-hamburger': PhosphorIconsRegular.hamburger,
    'ph-pizza': PhosphorIconsRegular.pizza,
    'ph-bread': PhosphorIconsRegular.bread,
    'ph-cake': PhosphorIconsRegular.cake,
    'ph-cookie': PhosphorIconsRegular.cookie,
    'ph-bowl-food': PhosphorIconsRegular.bowlFood,
    'ph-bowl-steam': PhosphorIconsRegular.bowlSteam,
    'ph-cooking-pot': PhosphorIconsRegular.cookingPot,
    'ph-coffee': PhosphorIconsRegular.coffee,
    'ph-coffee-bean': PhosphorIconsRegular.coffeeBean,
    'ph-tea-bag': PhosphorIconsRegular.teaBag,
    'ph-wine': PhosphorIconsRegular.wine,
    'ph-beer-bottle': PhosphorIconsRegular.beerBottle,
    'ph-brandy': PhosphorIconsRegular.brandy,
    'ph-martini': PhosphorIconsRegular.martini,
    'ph-cheese': PhosphorIconsRegular.cheese,
    'ph-egg': PhosphorIconsRegular.egg,
    'ph-egg-crack': PhosphorIconsRegular.eggCrack,
    'ph-fish': PhosphorIconsRegular.fish,
    'ph-fish-simple': PhosphorIconsRegular.fishSimple,
    'ph-carrot': PhosphorIconsRegular.carrot,
    'ph-orange': PhosphorIconsRegular.orange,
    'ph-orange-slice': PhosphorIconsRegular.orangeSlice,
    'ph-pepper': PhosphorIconsRegular.pepper,
    'ph-ice-cream': PhosphorIconsRegular.iceCream,
    'ph-popcorn': PhosphorIconsRegular.popcorn,
    'ph-fork-knife': PhosphorIconsRegular.forkKnife,
    'ph-knife': PhosphorIconsRegular.knife,
    'fa-hotdog': PhosphorIconsRegular.hamburger,
    'md-kebab': Icons.kebab_dining, // Похоже на мясо на шампуре (кебаб/шаурма)
    'md-croissant': Icons.bakery_dining, // Круассан (выпечка)
    'md-soup': Icons.soup_kitchen, // Суп
    'md-tapas': Icons.tapas, // Закуски/тапас
  };

  static IconData? getIcon(String? iconName, {IconData? fallback}) {
    if (iconName == null || iconName.isEmpty) return fallback;
    
    // Remove 'icon:' prefix if present
    final cleanName = iconName.startsWith('icon:') ? iconName.substring(5) : iconName;
    
    final icon = _iconMap[cleanName];
    if (icon != null && icon is IconData) {
      return icon;
    }
    return fallback;
  }

  static Widget buildIcon(String? iconName, {double? size, Color? color, IconData? fallback}) {
    if (iconName == null || iconName.isEmpty) {
      return fallback != null ? Icon(fallback, size: size, color: color) : const SizedBox.shrink();
    }
    
    final cleanName = iconName.startsWith('icon:') ? iconName.substring(5) : iconName;
    if (cleanName.startsWith('svg:')) {
      final svgName = cleanName.substring(4);
      return SvgPicture.asset(
        'assets/icons/$svgName.svg',
        width: size ?? 24,
        height: size ?? 24,
        colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
        placeholderBuilder: (context) => fallback != null ? Icon(fallback, size: size, color: color) : const SizedBox.shrink(),
      );
    }
    
    final icon = _iconMap[cleanName];
    
    if (icon == null) {
      return fallback != null ? Icon(fallback, size: size, color: color) : const SizedBox.shrink();
    }
    
    if (icon is FaIconData) {
      return FaIcon(icon, size: size, color: color);
    } else if (icon is IconData) {
      return Icon(icon, size: size, color: color);
    }
    
    return fallback != null ? Icon(fallback, size: size, color: color) : const SizedBox.shrink();
  }

  static List<String> get availableIcons => _iconMap.keys.toList();
}
