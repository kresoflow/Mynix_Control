import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class DateTimePickerCalendar extends StatelessWidget {
  final DateTime displayedMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  const DateTimePickerCalendar({
    super.key,
    required this.displayedMonth,
    required this.selectedDate,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  static const List<String> _months = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
  ];

  static const List<String> _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final daysInMonth = DateUtils.getDaysInMonth(displayedMonth.year, displayedMonth.month);
    final firstDayOffset = (DateTime(displayedMonth.year, displayedMonth.month, 1).weekday - 1);
    final totalCells = ((firstDayOffset + daysInMonth + 6) ~/ 7) * 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Панель месяца и года ──────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(PhosphorIconsRegular.caretLeft, size: 16),
                onPressed: () {
                  onMonthChanged(DateTime(displayedMonth.year, displayedMonth.month - 1));
                },
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const Spacer(),

              // Выбор месяца
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: displayedMonth.month,
                  isDense: true,
                  dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  items: List.generate(12, (i) {
                    return DropdownMenuItem(
                      value: i + 1,
                      child: Text(_months[i]),
                    );
                  }),
                  onChanged: (m) {
                    if (m != null) {
                      onMonthChanged(DateTime(displayedMonth.year, m));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Выбор года
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: displayedMonth.year,
                  isDense: true,
                  dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandPrimary,
                  ),
                  items: List.generate(16, (i) {
                    final y = 2020 + i;
                    return DropdownMenuItem(
                      value: y,
                      child: Text('$y'),
                    );
                  }),
                  onChanged: (y) {
                    if (y != null) {
                      onMonthChanged(DateTime(y, displayedMonth.month));
                    }
                  },
                ),
              ),
              const Spacer(),

              IconButton(
                icon: const Icon(PhosphorIconsRegular.caretRight, size: 16),
                onPressed: () {
                  onMonthChanged(DateTime(displayedMonth.year, displayedMonth.month + 1));
                },
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Дни недели ────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekdays.map((w) {
            final isWeekend = w == 'Сб' || w == 'Вс';
            return SizedBox(
              width: 36,
              child: Center(
                child: Text(
                  w,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isWeekend ? AppColors.danger.withValues(alpha: 0.8) : Colors.grey,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),

        // ── Сетка дней месяца ─────────────────────────────────────
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - firstDayOffset + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox();
            }

            final cellDate = DateTime(displayedMonth.year, displayedMonth.month, dayNumber);
            final isSelected = cellDate.year == selectedDate.year &&
                cellDate.month == selectedDate.month &&
                cellDate.day == selectedDate.day;
            final isToday = cellDate.year == now.year &&
                cellDate.month == now.month &&
                cellDate.day == now.day;

            return InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => onDateSelected(cellDate),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandPrimary
                      : (isToday ? (isDark ? Colors.white10 : Colors.black12) : Colors.transparent),
                  borderRadius: BorderRadius.circular(6),
                  border: isToday && !isSelected
                      ? Border.all(color: AppColors.brandPrimary, width: 1.2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
