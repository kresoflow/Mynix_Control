import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Future<DateTime?> showMynixDateTimePicker(
  BuildContext context, {
  DateTime? initialDateTime,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => _MynixDateTimePickerDialog(
      initialDateTime: initialDateTime ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2035),
    ),
  );
}

class _MynixDateTimePickerDialog extends StatefulWidget {
  final DateTime initialDateTime;
  final DateTime firstDate;
  final DateTime lastDate;

  const _MynixDateTimePickerDialog({
    required this.initialDateTime,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_MynixDateTimePickerDialog> createState() => _MynixDateTimePickerDialogState();
}

class _MynixDateTimePickerDialogState extends State<_MynixDateTimePickerDialog> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  late int _hour;
  late int _minute;

  static const List<String> _months = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
  ];

  static const List<String> _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDateTime.year,
      widget.initialDateTime.month,
      widget.initialDateTime.day,
    );
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _hour = widget.initialDateTime.hour;
    _minute = widget.initialDateTime.minute;
  }

  void _setQuickDate(int offsetDays) {
    final target = DateTime.now().add(Duration(days: offsetDays));
    setState(() {
      _selectedDate = DateTime(target.year, target.month, target.day);
      _displayedMonth = DateTime(target.year, target.month);
    });
  }

  void _setQuickTime(int h, int m) {
    setState(() {
      _hour = h.clamp(0, 23);
      _minute = m.clamp(0, 59);
    });
  }

  DateTime _getFinalDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _hour,
      _minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final daysInMonth = DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
    final firstDayOffset = (DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday - 1);
    final totalCells = ((firstDayOffset + daysInMonth + 6) ~/ 7) * 7;

    return MynixDialog(
      title: 'Дата и время документа',
      icon: PhosphorIconsRegular.calendarBlank,
      width: 410,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Быстрые кнопки дат ────────────────────────────────────
            Row(
              children: [
                _buildQuickChip('Сегодня', () => _setQuickDate(0), isDark),
                const SizedBox(width: 8),
                _buildQuickChip('Вчера', () => _setQuickDate(-1), isDark),
                const SizedBox(width: 8),
                _buildQuickChip('Позавчера', () => _setQuickDate(-2), isDark),
              ],
            ),
            const SizedBox(height: 12),

            // ── Компактный переключатель Месяца и Года ────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      setState(() {
                        _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
                      });
                    },
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const Spacer(),

                  // Выбор месяца
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _displayedMonth.month,
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
                          setState(() => _displayedMonth = DateTime(_displayedMonth.year, m));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Выбор года
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _displayedMonth.year,
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
                          setState(() => _displayedMonth = DateTime(y, _displayedMonth.month));
                        }
                      },
                    ),
                  ),
                  const Spacer(),

                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.caretRight, size: 16),
                    onPressed: () {
                      setState(() {
                        _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
                      });
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

            // ── Сетка дней месяца (компактная, без сжатия) ───────────
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

                final cellDate = DateTime(_displayedMonth.year, _displayedMonth.month, dayNumber);
                final isSelected = cellDate.year == _selectedDate.year &&
                    cellDate.month == _selectedDate.month &&
                    cellDate.day == _selectedDate.day;
                final isToday = cellDate.year == now.year &&
                    cellDate.month == now.month &&
                    cellDate.day == now.day;

                return InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    setState(() => _selectedDate = cellDate);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brandPrimary
                          : (isToday ? (isDark ? Colors.white10 : Colors.black12) : Colors.transparent),
                      borderRadius: BorderRadius.circular(6),
                      border: isToday && !isSelected
                          ? Border.all(color: AppColors.brandPrimary, width: 1)
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
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Встроенный селектор времени (в едином стиле) ─────────
            Row(
              children: [
                const Icon(PhosphorIconsRegular.clock, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Время:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),

                // Часы
                _buildTimeStepper(_hour, 23, (h) => setState(() => _hour = h), isDark),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                // Минуты
                _buildTimeStepper(_minute, 59, (m) => setState(() => _minute = m), isDark),

                const Spacer(),
                _buildQuickTimeChip('Сейчас', () => _setQuickTime(DateTime.now().hour, DateTime.now().minute), isDark),
                const SizedBox(width: 4),
                _buildQuickTimeChip('10:00', () => _setQuickTime(10, 0), isDark),
                const SizedBox(width: 4),
                _buildQuickTimeChip('18:00', () => _setQuickTime(18, 0), isDark),
              ],
            ),
          ],
        ),
      ),
      actions: [
        AppGhostButton(
          label: 'Отмена',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        AppPrimaryButton(
          label: 'Применить',
          icon: PhosphorIconsRegular.check,
          width: null,
          onPressed: () => Navigator.pop(context, _getFinalDateTime()),
        ),
      ],
    );
  }

  Widget _buildTimeStepper(int value, int max, ValueChanged<int> onChanged, bool isDark) {
    final isMinute = max == 59;
    return PopupMenuButton<int>(
      initialValue: value,
      tooltip: isMinute ? 'Выбрать минуты' : 'Выбрать часы',
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) {
        final step = isMinute ? 5 : 1;
        return List.generate((max ~/ step) + 1, (i) {
          final v = i * step;
          return PopupMenuItem(
            value: v,
            height: 30,
            child: Text(
              v.toString().padLeft(2, '0'),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: v == value ? FontWeight.bold : FontWeight.normal,
                color: v == value ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          );
        });
      },
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'monospace'),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText),
        ),
      ),
    );
  }

  Widget _buildQuickTimeChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black12,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
        ),
      ),
    );
  }
}
