
import 'package:mynix_frontend/features/settings/models/user_model.dart';
import 'package:mynix_frontend/features/settings/bloc/user_bloc.dart';
import 'package:mynix_frontend/features/settings/repository/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/core/theme/theme_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';

import 'package:mynix_frontend/features/pos/bloc/shift_event.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_event.dart';

import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:dio/dio.dart';

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 768) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Настройки', style: AppTextStyles.h1.copyWith(color: isDark ? AppColors.darkText : AppColors.lightText)),
                          _buildProfileMenu(context, isDark),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_categories.length, (index) {
                        final category = _categories[index];
                        final isSelected = index == _selectedIndex;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(category.title),
                            avatar: Icon(category.icon, size: 18, color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedIndex = index);
                              }
                            },
                            selectedColor: AppColors.brandPrimary,
                            backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                            labelStyle: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
                            ),
                          ),
                        );
                      }),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildCategoryContent(isDark),
                ),
              ],
            );
          }

          // Desktop/Tablet layout
          return Row(
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
          );
        }
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

  Widget _buildProfileMenu(BuildContext context, bool isDark) {
    return PopupMenuButton<String>(
      tooltip: 'Профиль пользователя',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 8,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandPrimary.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Icon(PhosphorIconsRegular.user, size: 24, color: AppColors.brandPrimary),
        ),
      ),
      onSelected: (value) {
        if (value == 'close_shift') {
          _showCloseShiftDialog(context);
        } else if (value == 'logout') {
          context.read<AuthBloc>().add(LoggedOut());
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Владелец платформы', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.lightText)),
              Text('Полный доступ', style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'close_shift',
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.lockKey, color: AppColors.danger, size: 20),
              const SizedBox(width: 12),
              Text('Закрыть смену', style: AppTextStyles.body.copyWith(color: AppColors.danger)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.signOut, color: AppColors.darkSubtext, size: 20),
              const SizedBox(width: 12),
              Text('Выйти из аккаунта', style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }

  void _showCloseShiftDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Закрытие смены'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Введите фактическую сумму наличных в кассе (Z-отчет):'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Сумма (с)',
                prefixIcon: Icon(PhosphorIconsRegular.money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              context.read<ShiftBloc>().add(CloseShiftRequested(amount));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('ЗАКРЫТЬ'),
          ),
        ],
      ),
    );
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
            SizedBox(width: 16),
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

class _GeneralSettings extends StatefulWidget {
  final bool isDark;
  const _GeneralSettings({required this.isDark});

  @override
  State<_GeneralSettings> createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<_GeneralSettings> {
  bool _isLoading = true;
  bool _useKds = true;
  bool _enableInventory = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final dio = apiClient.dio;
      final response = await dio.get('/settings/');
      setState(() {
        _useKds = response.data['use_kds'];
        _enableInventory = response.data['enable_inventory_deduction'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching settings: $e");
    }
  }

  Future<void> _updateSettings(bool useKds, bool enableInv) async {
    try {
      final dio = apiClient.dio;
      await dio.put('/settings/', data: {
        'use_kds': useKds,
        'enable_inventory_deduction': enableInv,
      });
      setState(() {
        _useKds = useKds;
        _enableInventory = enableInv;
      });
    } catch (e) {
      print("Error updating settings: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка сохранения настроек')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(40),
          children: [
            _buildHeader('Функции заведения', isDark),
            const SizedBox(height: 32),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsRow(
                  isDark: isDark,
                  title: 'Использовать экран повара (KDS)',
                  subtitle: 'Если выключено, заказы пропускают кухню и сразу готовы',
                  trailing: Switch(
                    value: _useKds,
                    activeColor: AppColors.brandPrimary,
                    onChanged: (val) => _updateSettings(val, _enableInventory),
                  ),
                ),
                _SettingsRow(
                  isDark: isDark,
                  title: 'Списание ингредиентов',
                  subtitle: 'Минусовать сырье по тех. картам при продаже',
                  trailing: Switch(
                    value: _enableInventory,
                    activeColor: AppColors.brandPrimary,
                    onChanged: (val) => _updateSettings(_useKds, val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
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
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildThemeVariantBtn(
                            context,
                            isDark: isDark,
                            label: 'Светлая (Basic)',
                            isSelected: themeMode == ThemeMode.light && state.themeVariant == 'basic',
                            onTap: () {
                              context.read<SettingsBloc>().add(const UpdateThemeVariant('basic'));
                              if (themeMode != ThemeMode.light) {
                                context.read<ThemeBloc>().add(ThemeEvent.toggleTheme);
                              }
                            },
                          ),
                          _buildThemeVariantBtn(
                            context,
                            isDark: isDark,
                            label: 'Светлая (Cream)',
                            isSelected: themeMode == ThemeMode.light && state.themeVariant == 'soft_cream',
                            onTap: () {
                              context.read<SettingsBloc>().add(const UpdateThemeVariant('soft_cream'));
                              if (themeMode != ThemeMode.light) {
                                context.read<ThemeBloc>().add(ThemeEvent.toggleTheme);
                              }
                            },
                          ),
                          _buildThemeVariantBtn(
                            context,
                            isDark: isDark,
                            label: 'Светлая (Contrast)',
                            isSelected: themeMode == ThemeMode.light && state.themeVariant == 'high_contrast_light',
                            onTap: () {
                              context.read<SettingsBloc>().add(const UpdateThemeVariant('high_contrast_light'));
                              if (themeMode != ThemeMode.light) {
                                context.read<ThemeBloc>().add(ThemeEvent.toggleTheme);
                              }
                            },
                          ),
                          _buildThemeVariantBtn(
                            context,
                            isDark: isDark,
                            label: 'Темная (Ember)',
                            isSelected: themeMode == ThemeMode.dark && state.themeVariant == 'basic',
                            onTap: () {
                              context.read<SettingsBloc>().add(const UpdateThemeVariant('basic'));
                              if (themeMode != ThemeMode.dark) {
                                context.read<ThemeBloc>().add(ThemeEvent.toggleTheme);
                              }
                            },
                          ),
                          _buildThemeVariantBtn(
                            context,
                            isDark: isDark,
                            label: 'Темная (Deep Ocean)',
                            isSelected: themeMode == ThemeMode.dark && state.themeVariant == 'deep_ocean',
                            onTap: () {
                              context.read<SettingsBloc>().add(const UpdateThemeVariant('deep_ocean'));
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
                  trailing: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCurrencyBtn(context, isDark, state, '₽', 'Рубль'),
                      _buildCurrencyBtn(context, isDark, state, '₸', 'Тенге'),
                      _buildCurrencyBtn(context, isDark, state, 'с', 'TJS'),
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
                  trailing: Switch(value: true, onChanged: (_) {}, activeThumbColor: AppColors.brandPrimary),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
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
              trailing: Switch(value: true, onChanged: (_) {}, activeThumbColor: AppColors.brandPrimary),
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
    return BlocProvider(
      create: (context) => UserBloc(repository: UserRepository())..add(LoadUsers()),
      child: _PersonnelSettingsView(isDark: isDark),
    );
  }
}

class _PersonnelSettingsView extends StatelessWidget {
  final bool isDark;
  const _PersonnelSettingsView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(40),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Управление персоналом',
                  style: AppTextStyles.h2.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                InkWell(
                  onTap: () => _showAddUserDialog(context, isDark, state.roles),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+ Добавить сотрудника',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (state.users.isEmpty)
              const Center(child: Text("Нет сотрудников"))
            else
              _SettingsCard(
                isDark: isDark,
                children: [
                  for (int i = 0; i < state.users.length; i++) ...[
                    _SettingsRow(
                      isDark: isDark,
                      title: '${state.users[i].fullName} (${state.users[i].roles.join(", ")})',
                      subtitle: 'Логин: ${state.users[i].username}',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(PhosphorIconsRegular.pencilSimple, color: AppColors.brandPrimary),
                            onPressed: () => _showEditUserDialog(context, isDark, state.roles, state.users[i]),
                          ),
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.trash, color: Colors.red),
                            onPressed: () {
                              context.read<UserBloc>().add(DeleteUser(state.users[i].id));
                            },
                          ),
                        ],
                      ),
                    ),
                    if (i < state.users.length - 1)
                      _SettingsDivider(isDark: isDark),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }


  void _showEditUserDialog(BuildContext parentContext, bool isDark, List<Role> availableRoles, StaffUser user) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: parentContext.read<UserBloc>(),
          child: _EditUserDialog(isDark: isDark, roles: availableRoles, user: user),
        );
      },
    );
  }
  void _showAddUserDialog(BuildContext parentContext, bool isDark, List<Role> availableRoles) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: parentContext.read<UserBloc>(),
          child: _AddUserDialog(isDark: isDark, roles: availableRoles),
        );
      },
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  final bool isDark;
  final List<Role> roles;
  const _AddUserDialog({required this.isDark, required this.roles});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  int? _selectedRoleId;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
      title: Text("Новый сотрудник", style: TextStyle(color: widget.isDark ? AppColors.darkText : AppColors.lightText)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _fullNameCtrl,
              decoration: InputDecoration(labelText: "ФИО (например: Анна Кассир)"),
            ),
            TextField(
              controller: _usernameCtrl,
              decoration: InputDecoration(labelText: "Логин (например: anna_cash)"),
            ),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: "Пароль"),
            ),
            TextField(
              controller: _pinCtrl,
              decoration: InputDecoration(labelText: "Пин-код (Опционально)"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedRoleId,
              decoration: const InputDecoration(labelText: "Роль"),
              items: widget.roles.map((r) {
                return DropdownMenuItem(value: r.id, child: Text(r.name));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedRoleId = val;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Отмена"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_usernameCtrl.text.isEmpty || _fullNameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty || _selectedRoleId == null) {
              return;
            }
            context.read<UserBloc>().add(CreateUser(
              username: _usernameCtrl.text,
              fullName: _fullNameCtrl.text,
              password: _passwordCtrl.text,
              pinCode: _pinCtrl.text.isNotEmpty ? _pinCtrl.text : null,
              roleIds: [_selectedRoleId!],
            ));
            Navigator.pop(context);
          },
          child: const Text("Создать"),
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
              trailing: Switch(value: true, onChanged: (_) {}, activeThumbColor: AppColors.brandPrimary),
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
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Flexible(
            flex: 2,
            child: trailing,
          ),
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


class _EditUserDialog extends StatefulWidget {
  final bool isDark;
  final List<Role> roles;
  final StaffUser user;
  const _EditUserDialog({required this.isDark, required this.roles, required this.user});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late TextEditingController _usernameCtrl;
  late TextEditingController _fullNameCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _pinCtrl;
  int? _selectedRoleId;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.user.username);
    _fullNameCtrl = TextEditingController(text: widget.user.fullName);
    _passwordCtrl = TextEditingController();
    _pinCtrl = TextEditingController();
    
    // Attempt to match the existing role
    if (widget.user.roles.isNotEmpty) {
      final roleName = widget.user.roles.first;
      try {
        final role = widget.roles.firstWhere((r) => r.name == roleName);
        _selectedRoleId = role.id;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
      title: Text("Редактировать сотрудника", style: TextStyle(color: widget.isDark ? AppColors.darkText : AppColors.lightText)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _fullNameCtrl,
              decoration: InputDecoration(labelText: "ФИО"),
            ),
            TextField(
              controller: _usernameCtrl,
              decoration: InputDecoration(labelText: "Логин"),
            ),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: "Новый пароль (оставьте пустым, если не меняете)"),
            ),
            TextField(
              controller: _pinCtrl,
              decoration: InputDecoration(labelText: "Новый Пин-код (оставьте пустым, если не меняете)"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedRoleId,
              decoration: const InputDecoration(labelText: "Роль"),
              items: widget.roles.map((r) {
                return DropdownMenuItem(value: r.id, child: Text(r.name));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedRoleId = val;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Отмена"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_usernameCtrl.text.isEmpty || _fullNameCtrl.text.isEmpty) {
              return;
            }
            context.read<UserBloc>().add(UpdateUser(
              userId: widget.user.id,
              username: _usernameCtrl.text,
              fullName: _fullNameCtrl.text,
              password: _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
              pinCode: _pinCtrl.text.isNotEmpty ? _pinCtrl.text : null,
              roleIds: _selectedRoleId != null ? [_selectedRoleId!] : null,
            ));
            Navigator.pop(context);
          },
          child: const Text("Сохранить"),
        ),
      ],
    );
  }


}
