import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import 'package:retail_os_frontend/core/theme/app_text_styles.dart';
import 'package:retail_os_frontend/features/inventory/models/ingredient.dart';

class ReceiveRetailItemWidget extends StatefulWidget {
  final Ingredient product;
  final double quantity;
  final ValueChanged<double> onChanged;

  const ReceiveRetailItemWidget({
    Key? key,
    required this.product,
    required this.quantity,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ReceiveRetailItemWidget> createState() =>
      _ReceiveRetailItemWidgetState();
}

class _ReceiveRetailItemWidgetState extends State<ReceiveRetailItemWidget> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.quantity > 0 ? widget.quantity.toStringAsFixed(0) : '',
    );
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        if (_controller.text.isEmpty) {
          _controller.text = '0';
        }
      } else {
        if (_controller.text == '0') {
          _controller.text = '';
        }
      }
    });
  }

  @override
  void didUpdateWidget(ReceiveRetailItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      if (widget.quantity == 0) {
        if (!_focusNode.hasFocus) {
          _controller.text = '';
        }
      } else {
        final currentText = _controller.text;
        final currentVal = double.tryParse(currentText) ?? 0;
        if (currentVal != widget.quantity) {
          _controller.text = widget.quantity.toStringAsFixed(0);
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _increment() {
    widget.onChanged(widget.quantity + 1);
  }

  void _decrement() {
    if (widget.quantity > 0) {
      widget.onChanged(widget.quantity - 1);
    }
  }

  void _onTextChanged(String val) {
    final number = double.tryParse(val);
    if (number != null && number >= 0) {
      widget.onChanged(number);
    } else if (val.isEmpty) {
      widget.onChanged(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'На складе: ${widget.product.currentStock} ${widget.product.unit}',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: widget.quantity > 0
                    ? AppColors.brandPrimary
                    : Colors.grey,
                onPressed: widget.quantity > 0 ? _decrement : null,
              ),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                  ),
                  onChanged: _onTextChanged,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.brandPrimary,
                onPressed: _increment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
