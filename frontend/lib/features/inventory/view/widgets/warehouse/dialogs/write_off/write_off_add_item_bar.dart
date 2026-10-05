// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';

// ==============================================================================
// 2. СТРОКА БЫСТРОГО ПОИСКА И ДОБАВЛЕНИЯ ПОЗИЦИЙ
// ==============================================================================
/// [ИНВАРИАНТ] Поиск товаров/сырья с автоочисткой поля после выбора позиции.
class WriteOffAddItemBar extends StatefulWidget {
  final List<Ingredient> availableIngredients;
  final ValueChanged<Ingredient> onIngredientSelected;

  const WriteOffAddItemBar({
    super.key,
    required this.availableIngredients,
    required this.onIngredientSelected,
  });

  @override
  State<WriteOffAddItemBar> createState() => _WriteOffAddItemBarState();
}

class _WriteOffAddItemBarState extends State<WriteOffAddItemBar> {
  TextEditingController? _activeController;

  void _handleSelect(Ingredient item) {
    widget.onIngredientSelected(item);
    // [UX] Мгновенно очищаем поле в следующем кадре после обновления Autocomplete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activeController?.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Autocomplete<Ingredient>(
      displayStringForOption: (item) => item.name,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Ingredient>.empty();
        }
        final q = textEditingValue.text.toLowerCase().trim();
        return widget.availableIngredients.where(
          (item) => !item.isArchived && item.name.toLowerCase().contains(q),
        );
      },
      onSelected: _handleSelect,
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Container(
              width: 580,
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                itemBuilder: (context, index) {
                  final item = options.elementAt(index);
                  final isRetail = item.attributes?['is_retail'] == true;
                  final hasStock = item.currentStock > 0.001;

                  return ListTile(
                    dense: true,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.lightText,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: hasStock
                                ? AppColors.success
                                    .withValues(alpha: isDark ? 0.16 : 0.10)
                                : AppColors.danger
                                    .withValues(alpha: isDark ? 0.16 : 0.10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'В наличии: ${UnitFormatter.formatAmount(item.currentStock, item.unit)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: hasStock
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isRetail ? 'Витрина' : 'Сырье',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => onSelected(item),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        _activeController = textEditingController;

        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: textEditingController,
          builder: (context, value, _) {
            final hasText = value.text.isNotEmpty;
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              decoration: InputDecoration(
                hintText: 'Поиск номенклатуры для списания (сырье, товары)...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color:
                      isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
                prefixIcon: const Icon(
                  PhosphorIconsRegular.magnifyingGlass,
                  size: 18,
                ),
                suffixIcon: hasText
                    ? IconButton(
                        icon: const Icon(PhosphorIconsRegular.x, size: 16),
                        onPressed: () {
                          textEditingController.clear();
                          focusNode.requestFocus();
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor:
                    isDark ? AppColors.darkSurface : AppColors.lightSurface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppColors.brandPrimary,
                    width: 1.5,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
