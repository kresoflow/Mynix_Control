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
  late TimeOfDay _selectedTime;
  bool _isSelectingYearMonth = false;

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
    _selectedTime = TimeOfDay(
      hour: widget.initialDateTime.hour,
      minute: widget.initialDateTime.minute,
    );
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  void _setQuickDate(int offsetDays) {
    final now = DateTime.now();
    final target = now.add(Duration(days: offsetDays));
    setState(() {
      _selectedDate = DateTime(target.year, target.month, target.day);
      _displayedMonth = DateTime(target.year, target.month);
      _isSelectingYearMonth = false;
    });
  }

  void _setQuickTime(int hour, int minute) {
    setState(() {
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  DateTime _getFinalDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final daysInMonth = DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
    final firstDayOfWeek = (DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday - 1); // 0 = Mon

    return MynixDialog(
      title: 'Дата и время документа',
      icon: PhosphorIconsRegular.calendarBlank,
      width: 440,
      content: Column(
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
          const SizedBox(height: 14),

          // ── Переключатель месяца и года (с кнопкой быстрого выбора) ─
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.caretLeft, size: 18),
                  onPressed: _previousMonth,
                  splashRadius: 20,
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => setState(() => _isSelectingYearMonth = !_isSelectingYearMonth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_months[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isSelectingYearMonth ? PhosphorIconsRegular.caretUp : PhosphorIconsRegular.caretDown,
                          size: 14,
                          color: AppColors.brandPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.caretRight, size: 18),
                  onPressed: _nextMonth,
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (_isSelectingYearMonth) ...[
            // ── Сетка выбора месяцев ─────────────────────────────────
            SizedBox(
              height: 220,
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 2.2,
                ),
                itemBuilder: (context, index) {
                  final isCurrentMonth = _displayedMonth.month == index + 1;
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        _displayedMonth = DateTime(_displayedMonth.year, index + 1);
                        _isSelectingYearMonth = false;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrentMonth
                            ? AppColors.brandPrimary
                            : (isDark ? Colors.white10 : Colors.black12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _months[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.normal,
                            color: isCurrentMonth ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            // ── Заголовки дней недели ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _weekdays.map((w) {
                final isWeekend = w == 'Сб' || w == 'Вс';
                return SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      w,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isWeekend ? AppColors.danger.withValues(alpha: 0.8) : Colors.grey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),

            // ── Сетка дней месяца ─────────────────────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42, // 6 weeks
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - firstDayOfWeek + 1;
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
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _selectedDate = cellDate;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brandPrimary
                          : (isToday
                              ? (isDark ? Colors.white10 : Colors.black12)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isSelected
                          ? Border.all(color: AppColors.brandPrimary, width: 1.2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkText : AppColors.lightText),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── Время поставки ────────────────────────────────────────
          Row(
            children: [
              const Icon(PhosphorIconsRegular.clock, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Время:',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null) {
                    setState(() => _selectedTime = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const Spacer(),
              _buildQuickTimeChip('Сейчас', () => _setQuickTime(DateTime.now().hour, DateTime.now().minute), isDark),
              const SizedBox(width: 6),
              _buildQuickTimeChip('10:00', () => _setQuickTime(10, 0), isDark),
              const SizedBox(width: 6),
              _buildQuickTimeChip('18:00', () => _setQuickTime(18, 0), isDark),
            ],
          ),
        ],
      ),
      actions: [
        AppGhostButton(
          label: 'Отмена',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        AppPrimaryButton(
          label: 'Применить',
          icon: PhosphorIconsRegular.check,
          width: null,
          onPressed: () => Navigator.pop(context, _getFinalDateTime()),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText),
        ),
      ),
    );
  }

  Widget _buildQuickTimeChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black12,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
        ),
      ),
    );
  }
}
