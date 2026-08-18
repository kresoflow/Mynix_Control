import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Кастомное премиальное модальное окно выбора Даты и Времени в дизайн-системе Mynix Control.
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
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  int _quickDateIndex = 0; // 0 = Сегодня, -1 = Вчера, -2 = Позавчера, -99 = другое

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
    _hourController = TextEditingController(text: widget.initialDateTime.hour.toString().padLeft(2, '0'));
    _minuteController = TextEditingController(text: widget.initialDateTime.minute.toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _setQuickDate(int offsetDays) {
    final target = DateTime.now().add(Duration(days: offsetDays));
    setState(() {
      _quickDateIndex = offsetDays;
      _selectedDate = DateTime(target.year, target.month, target.day);
      _displayedMonth = DateTime(target.year, target.month);
    });
  }

  void _setQuickTime(int h, int m) {
    setState(() {
      _hourController.text = h.clamp(0, 23).toString().padLeft(2, '0');
      _minuteController.text = m.clamp(0, 59).toString().padLeft(2, '0');
    });
  }

  DateTime _getFinalDateTime() {
    final h = int.tryParse(_hourController.text) ?? 0;
    final m = int.tryParse(_minuteController.text) ?? 0;
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      h.clamp(0, 23),
      m.clamp(0, 59),
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
      width: 420,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Быстрые кнопки дат ────────────────────────────────────
            Row(
              children: [
                _buildQuickChip('Сегодня', () => _setQuickDate(0), _quickDateIndex == 0, isDark),
                const SizedBox(width: 8),
                _buildQuickChip('Вчера', () => _setQuickDate(-1), _quickDateIndex == -1, isDark),
                const SizedBox(width: 8),
                _buildQuickChip('Позавчера', () => _setQuickDate(-2), _quickDateIndex == -2, isDark),
              ],
            ),
            const SizedBox(height: 12),

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
                    setState(() {
                      _quickDateIndex = -99;
                      _selectedDate = cellDate;
                    });
                  },
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
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Блок выбора времени (стильные цифровые блоки) ────────
            Row(
              children: [
                const Icon(PhosphorIconsRegular.clock, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Время:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),

                // Цифровой блок часов
                _buildDigitalTimeBox(_hourController, 23, isDark),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                // Цифровой блок минут
                _buildDigitalTimeBox(_minuteController, 59, isDark),

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

  Widget _buildDigitalTimeBox(TextEditingController controller, int max, bool isDark) {
    return Container(
      width: 42,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 2,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) {
            final parsed = int.tryParse(val);
            if (parsed != null && parsed > max) {
              controller.text = max.toString().padLeft(2, '0');
            }
          },
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap, bool isSelected, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary.withValues(alpha: 0.2)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTimeChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
