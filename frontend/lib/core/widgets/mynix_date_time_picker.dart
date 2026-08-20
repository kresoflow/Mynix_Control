import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'date_time_picker_calendar.dart';
import 'date_time_picker_time_row.dart';

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

            // ── Календарь (месяц, сетка, выбор) ───────────────────────
            DateTimePickerCalendar(
              displayedMonth: _displayedMonth,
              selectedDate: _selectedDate,
              onMonthChanged: (m) => setState(() => _displayedMonth = m),
              onDateSelected: (d) => setState(() {
                _quickDateIndex = -99;
                _selectedDate = d;
              }),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Блок выбора времени ───────────────────────────────────
            DateTimePickerTimeRow(
              hourController: _hourController,
              minuteController: _minuteController,
              onQuickTimeSelected: _setQuickTime,
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
}
