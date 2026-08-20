import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_state.dart';
import 'package:mynix_frontend/features/pos/view/widgets/pos_settings_modal.dart';
import 'package:mynix_frontend/features/pos/view/widgets/pos_shift_hub_modal.dart';
import 'package:mynix_frontend/features/pos/view/widgets/open_shift_modal.dart';

class PosBreadcrumbBar extends StatelessWidget {
  final List<dynamic> history;
  final VoidCallback? onBack;
  final VoidCallback onRoot;
  final ValueChanged<int> onCrumb;

  const PosBreadcrumbBar({
    super.key,
    required this.history,
    required this.onBack,
    required this.onRoot,
    required this.onCrumb,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(PhosphorIconsRegular.caretLeft, size: 16),
              color: AppColors.darkSubtext,
              onPressed: onBack,
              tooltip: 'Назад',
            ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onRoot,
                    child: Text(
                      'Меню',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: history.isEmpty
                            ? AppColors.brandPrimary
                            : AppColors.darkSubtext,
                      ),
                    ),
                  ),
                  for (int i = 0; i < history.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(PhosphorIconsRegular.caretRight,
                          size: 16, color: AppColors.darkSubtext),
                    ),
                    GestureDetector(
                      onTap: i == history.length - 1 ? null : () => onCrumb(i),
                      child: Text(
                        history[i].name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: i == history.length - 1
                              ? AppColors.brandPrimary
                              : AppColors.darkSubtext,
                          fontWeight: i == history.length - 1
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          BlocBuilder<ShiftBloc, ShiftState>(
            builder: (context, shiftState) {
              final isOpen = shiftState is ShiftOpen;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (isOpen) {
                        showShiftHubModal(context);
                      } else {
                        showOpenShiftDialog(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isOpen ? AppColors.brandTertiary.withValues(alpha: 0.12) : AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isOpen ? AppColors.brandTertiary.withValues(alpha: 0.35) : AppColors.danger.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOpen ? AppColors.brandTertiary : AppColors.danger,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOpen ? 'Смена' : 'Закрыта',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isOpen ? AppColors.brandTertiary : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.slidersHorizontal),
            color: AppColors.darkSubtext,
            onPressed: () => PosSettingsModal.show(context),
            tooltip: 'Настройки кассы',
          ),
        ],
      ),
    );
  }
}
