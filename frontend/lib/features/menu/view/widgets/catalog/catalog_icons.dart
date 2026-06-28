import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Widget buildCategoryIcon(String name, {required double size, required Color color}) {
  final lower = name.toLowerCase();
  if (lower.contains('пицца')) return Icon(PhosphorIcons.pizza(), size: size, color: color);
  if (lower.contains('бургер')) return Icon(PhosphorIcons.hamburger(), size: size, color: color);
  if (lower.contains('напит') || lower.contains('вода') || lower.contains('сок') || lower.contains('газировк') || lower.contains('лимонад') || lower.contains('энергетик')) return FaIcon(FontAwesomeIcons.bottleWater, size: size, color: color);
  if (lower.contains('чай') || lower.contains('чаи') || lower.contains('кофе')) return Icon(PhosphorIcons.coffee(), size: size, color: color);
  if (lower.contains('соус')) return Icon(PhosphorIcons.drop(), size: size, color: color);
  if (lower.contains('гарнир') || lower.contains('салат')) return Icon(PhosphorIcons.bowlFood(), size: size, color: color);
  if (lower.contains('десерт') || lower.contains('сладкое') || lower.contains('морожен')) return Icon(PhosphorIcons.cookie(), size: size, color: color);
  if (lower.contains('хотдог')) return Icon(PhosphorIcons.hamburger(), size: size, color: color);
  return Icon(PhosphorIcons.package(), size: size, color: color);
}
