import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import 'package:retail_os_frontend/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:retail_os_frontend/core/theme/theme_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  final List<_SettingsCategory> _categories = [
    _SettingsCategory(PhosphorIconsRegular.slidersHorizontal, 'Основные'),
    _SettingsCategory(PhosphorIconsRegular.printer, 'Оборудование'),
    _SettingsCategory(PhosphorIconsRegular.users, 'Персонал'),
    _SettingsCategory(PhosphorIconsRegular.receipt, 'Налоги и сборы'),
    _SettingsCategory(PhosphorIconsRegular.hardDrives, 'Система'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Row(
        children: [
          // Левая панель - список категорий
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Настройки',
                    style: AppTextStyles.h1.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = index == _selectedIndex;

                      return _CategoryTile(
                        category: category,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Правая панель - контент выбранной категории
          Expanded(
            child: _buildCategoryContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(bool isDark) {
    switch (_selectedIndex) {
      case 0:
        return _GeneralSettings(isDark: isDark);
      case 1:
        return _HardwareSettings(isDark: isDark);
      case 2:
        return _PersonnelSettings(isDark: isDark);
      case 3:
        return _TaxSettings(isDark: isDark);
      case 4:
        return _SystemSettings(isDark: isDark);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _SettingsCategory {
  final IconData icon;
  final String title;

  _SettingsCategory(this.icon, this.title);
}

class _CategoryTile extends StatelessWidget {
  final _SettingsCategory category;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppColors.brandPrimary
        : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(category.icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              category.title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected
                    ? (isDark ? AppColors.darkText : AppColors.lightText)
                    : color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Вкладки настроек (Заглушки UI)
// -----------------------------------------------------------------------------

class _GeneralSettings extends StatelessWidget {
  final bool isDark;
  const _GeneralSettings({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(40),
          children: [
            _buildHeader('Внешний вид', isDark),
            const SizedBox(height: 32),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsRow(
                  isDark: isDark,
                  title: 'Цветовая схема (Тема)',
                  subtitle: 'Выбор светлой или темной темы',
                  trailing: BlocBuilder<ThemeBloc, ThemeMode>(
                    builder: (context, themeMode) {
                      return Row(
                        children: [
                          _buildThemeVariantBtn(
                            context,
                            isDark: isDark,
                            label: 'Светлая',
                            isSelected: themeMode == ThemeMode.light,
                            onTap: () {
                              if (themeMode != ThemeMode.light) {
                                context.read<ThemeBloc>().add(ThemeEvent.toggleTheme);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildThemeVariantBtn(
                            context,
                            isDark: isDark,
                            label: 'Темная (Ember)',
                            isSelected: themeMode == ThemeMode.dark && state.themeVariant == 'basic',
                            onTap: () {
                              if (state.themeVariant != 'basic') {
                                context.read<SettingsBloc>().add(const UpdateThemeVariant('basic'));
                              }
                              if (themeMode != ThemeMode.dark) {
                                context.read<ThemeBloc>().add(ThemeEvent.toggleTheme);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildThemeVariantBtn(
                            context,
                            isDark: isDark,
                            label: 'Темная (Deep Ocean)',
                            isSelected: themeMode == ThemeMode.dark && state.themeVariant == 'deep_ocean',
                            onTap: () {
                              if (state.themeVariant != 'deep_ocean') {
                                context.read<SettingsBloc>().add(const UpdateThemeVariant('deep_ocean'));
                              }
                              if (themeMode != ThemeMode.dark) {
                                context.read<ThemeBloc>().add(ThemeEvent.toggleTheme);
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildHeader('Региональные настройки', isDark),
            const SizedBox(height: 32),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsRow(
                  isDark: isDark,
                  title: 'Валюта по умолчанию',
                  subtitle: 'Отображается в кассе, чеках и аналитике',
                  trailing: Row(
                    children: [
                      _buildCurrencyBtn(context, isDark, state, '₽', 'Рубль'),
                      const SizedBox(width: 8),
                      _buildCurrencyBtn(context, isDark, state, '₸', 'Тенге'),
                      const SizedBox(width: 8),
                      _buildCurrencyBtn(context, isDark, state, 'с', 'Сом'),
                    ],
                  ),
                ),
                _SettingsDivider(isDark: isDark),
                _SettingsRow(
                  isDark: isDark,
                  title: 'Часовой пояс',
                  subtitle: 'Определяет время чеков и смен',
                  trailing: _DropdownStub(isDark: isDark, value: 'GMT+3 (Москва)'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildHeader('Системные настройки', isDark),
            const SizedBox(height: 32),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsRow(
                  isDark: isDark,
                  title: 'Звуковые уведомления',
                  subtitle: 'Звуки при успешной оплате или ошибках',
                  trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppColors.brandPrimary),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeVariantBtn(
    BuildContext context, {
    required bool isDark,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary.withValues(alpha: 0.15) : (isDark ? AppColors.darkBg : AppColors.lightBg),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyBtn(BuildContext context, bool isDark, SettingsState state, String code, String name) {
    final isSelected = state.currency == code;
    return InkWell(
      onTap: () {
        context.read<SettingsBloc>().add(UpdateCurrency(code));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary.withValues(alpha: 0.15) : (isDark ? AppColors.darkBg : AppColors.lightBg),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          children: [
            Text(
              code,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HardwareSettings extends StatelessWidget {
  final bool isDark;
  const _HardwareSettings({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        _buildHeader('Оборудование', isDark),
        const SizedBox(height: 32),
        _SettingsCard(
          isDark: isDark,
          children: [
            _SettingsRow(
              isDark: isDark,
              title: 'Принтер чеков',
              subtitle: 'Не подключен',
              trailing: _ButtonStub(isDark: isDark, label: 'Поиск устройств', isPrimary: true),
            ),
            _SettingsDivider(isDark: isDark),
            _SettingsRow(
              isDark: isDark,
              title: 'Шаблон чека',
              subtitle: 'Стандартный (Ширина 80мм)',
              trailing: _ButtonStub(isDark: isDark, label: 'Настроить', isPrimary: false),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SettingsCard(
          isDark: isDark,
          children: [
            _SettingsRow(
              isDark: isDark,
              title: 'Сканер штрих-кодов',
              subtitle: 'Режим эмуляции клавиатуры',
              trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppColors.brandPrimary),
            ),
          ],
        ),
      ],
    );
  }
}

class _PersonnelSettings extends StatelessWidget {
  final bool isDark;
  const _PersonnelSettings({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeader('Управление персоналом', isDark),
            _ButtonStub(isDark: isDark, label: '+ Добавить сотрудника', isPrimary: true),
          ],
        ),
        const SizedBox(height: 32),
        _SettingsCard(
          isDark: isDark,
          children: [
            _SettingsRow(
              isDark: isDark,
              title: 'Иван Иванов (Администратор)',
              subtitle: 'Полный доступ • PIN: ****',
              trailing: Icon(PhosphorIconsRegular.pencilSimple, color: AppColors.brandPrimary),
            ),
            _SettingsDivider(isDark: isDark),
            _SettingsRow(
              isDark: isDark,
              title: 'Анна Смирнова (Кассир)',
              subtitle: 'Касса, Возвраты • PIN: ****',
              trailing: Icon(PhosphorIconsRegular.pencilSimple, color: AppColors.brandPrimary),
            ),
          ],
        ),
      ],
    );
  }
}

class _TaxSettings extends StatelessWidget {
  final bool isDark;
  const _TaxSettings({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        _buildHeader('Налоги и сборы', isDark),
        const SizedBox(height: 32),
        _SettingsCard(
          isDark: isDark,
          children: [
            _SettingsRow(
              isDark: isDark,
              title: 'НДС по умолчанию',
              subtitle: 'Применяется ко всем новым товарам',
              trailing: _DropdownStub(isDark: isDark, value: 'Без НДС'),
            ),
            _SettingsDivider(isDark: isDark),
            _SettingsRow(
              isDark: isDark,
              title: 'Включать налоги в цену',
              subtitle: 'Цены в каталоге отображаются с учетом налога',
              trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppColors.brandPrimary),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SettingsCard(
          isDark: isDark,
          children: [
            _SettingsRow(
              isDark: isDark,
              title: 'Сервисный сбор (Чаевые)',
              subtitle: 'Автоматически добавляется к заказу',
              trailing: _DropdownStub(isDark: isDark, value: '10%'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SystemSettings extends StatelessWidget {
  final bool isDark;
  const _SystemSettings({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        _buildHeader('О системе', isDark),
        const SizedBox(height: 32),
        _SettingsCard(
          isDark: isDark,
          children: [
            _SettingsRow(
              isDark: isDark,
              title: 'Версия Mynix Control',
              subtitle: 'v1.0.0 (Сборка 42) — Последняя версия',
              trailing: _ButtonStub(isDark: isDark, label: 'Проверить обновления', isPrimary: false),
            ),
            _SettingsDivider(isDark: isDark),
            _SettingsRow(
              isDark: isDark,
              title: 'Статус локальной базы (Hive)',
              subtitle: 'Синхронизировано (Размер: 2.4 МБ)',
              trailing: _ButtonStub(isDark: isDark, label: 'Сбросить кэш', isPrimary: false),
            ),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// UI Утилиты
// -----------------------------------------------------------------------------

Widget _buildHeader(String title, bool isDark) {
  return Text(
    title,
    style: AppTextStyles.h1.copyWith(
      color: isDark ? AppColors.darkText : AppColors.lightText,
      fontSize: 28,
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsRow({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  final bool isDark;

  const _SettingsDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}

class _DropdownStub extends StatelessWidget {
  final bool isDark;
  final String value;

  const _DropdownStub({required this.isDark, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            PhosphorIconsRegular.caretDown,
            size: 16,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ],
      ),
    );
  }
}

class _ButtonStub extends StatelessWidget {
  final bool isDark;
  final String label;
  final bool isPrimary;

  const _ButtonStub({
    required this.isDark,
    required this.label,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.brandPrimary
            : (isDark ? AppColors.darkBg : AppColors.lightBg),
        borderRadius: BorderRadius.circular(8),
        border: isPrimary
            ? null
            : Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isPrimary
              ? Colors.white
              : (isDark ? AppColors.darkText : AppColors.lightText),
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
