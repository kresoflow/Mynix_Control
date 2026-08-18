import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

/// Открывает нативный календарь и селектор времени в стиле дизайн-системы.
/// Позволяет как выбирать дату/время кликом (циферблат, календарь),
/// так и вводить любые значения вручную с клавиатуры через иконку [⌨️].
Future<DateTime?> showMynixDateTimePicker(
  BuildContext context, {
  DateTime? initialDateTime,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final now = initialDateTime ?? DateTime.now();

  final themeData = Theme.of(context).copyWith(
    colorScheme: isDark
        ? ColorScheme.dark(
            primary: AppColors.brandPrimary,
            onPrimary: Colors.white,
            surface: AppColors.darkSurface,
            onSurface: AppColors.darkText,
            secondary: AppColors.brandPrimary,
          )
        : ColorScheme.light(
            primary: AppColors.brandPrimary,
            onPrimary: Colors.white,
            surface: AppColors.lightSurface,
            onSurface: AppColors.lightText,
            secondary: AppColors.brandPrimary,
          ),
    dialogTheme: DialogThemeData(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brandPrimary,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );

  // 1. Выбор даты (с возможностью ввода с клавиатуры через переключатель)
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: now,
    firstDate: firstDate ?? DateTime(2020),
    lastDate: lastDate ?? DateTime(2035),
    builder: (context, child) => Theme(data: themeData, child: child!),
  );

  if (pickedDate == null) return null;

  if (!context.mounted) return pickedDate;

  // 2. Выбор времени (циферблат или ввод с клавиатуры)
  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    builder: (context, child) => Theme(data: themeData, child: child!),
  );

  final hour = pickedTime?.hour ?? now.hour;
  final minute = pickedTime?.minute ?? now.minute;

  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    hour,
    minute,
  );
}
