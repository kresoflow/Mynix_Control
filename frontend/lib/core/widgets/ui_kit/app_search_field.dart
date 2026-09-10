import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final double? width;
  final double height;
  final bool autoFocus;

  const AppSearchField({
    super.key,
    this.controller,
    this.hintText = 'Поиск...',
    this.onChanged,
    this.onClear,
    this.width,
    this.height = 34,
    this.autoFocus = false,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _controller;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController();
      _isInternalController = true;
    } else {
      _controller = widget.controller!;
    }
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) {
          return TextField(
            controller: _controller,
            autofocus: widget.autoFocus,
            onChanged: widget.onChanged,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hintText,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                PhosphorIconsRegular.magnifyingGlass,
                size: 16,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(PhosphorIconsRegular.x, size: 14),
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      onPressed: () {
                        _controller.clear();
                        if (widget.onChanged != null) widget.onChanged!('');
                        if (widget.onClear != null) widget.onClear!();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          );
        },
      ),
    );
  }
}
