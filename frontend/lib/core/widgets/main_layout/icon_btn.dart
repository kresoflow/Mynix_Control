import 'package:flutter/material.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';

class IconBtn extends StatefulWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const IconBtn({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
  });

  @override
  State<IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = widget.color ?? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);

    return Tooltip(
      message: widget.tooltip ?? '',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _hovered
                  ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }
}
