import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/theme_bloc.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/features/settings/view/widgets/settings_ui_components.dart';

class GeneralSettingsTab extends StatefulWidget {
  final bool isDark;
  const GeneralSettingsTab({super.key, required this.isDark});

  @override
  State<GeneralSettingsTab> createState() => _GeneralSettingsTabState();
}

class _GeneralSettingsTabState extends State<GeneralSettingsTab> {
  bool _isLoading = true;
  bool _useKds = true;
  bool _useOrders = true;
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
        _useOrders = response.data['use_orders'] ?? true;
        _enableInventory = response.data['enable_inventory_deduction'];
        _isLoading = false;
      });
      if (mounted) {
        context.read<SettingsBloc>().add(
          UpdateFeatureFlags(useKds: _useKds, useOrders: _useOrders),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching settings: $e");
    }
  }

  Future<void> _updateSettings(bool useKds, bool useOrders, bool enableInv) async {
    try {
      final dio = apiClient.dio;
      await dio.put('/settings/', data: {
        'use_kds': useKds,
        'use_orders': useOrders,
        'enable_inventory_deduction': enableInv,
      });
      setState(() {
        _useKds = useKds;
        _useOrders = useOrders;
        _enableInventory = enableInv;
      });
      if (mounted) {
        context.read<SettingsBloc>().add(
          UpdateFeatureFlags(useKds: _useKds, useOrders: _useOrders),
        );
      }
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
            buildSettingsHeader('Функции заведения', isDark),
            const SizedBox(height: 32),
            SettingsCard(
              isDark: isDark,
              children: [
                SettingsRow(
                  isDark: isDark,
                  title: 'Использовать экран повара (KDS)',
                  subtitle: 'Если выключено, скрывает вкладку КДС и заказы сразу готовы',
                  trailing: Switch(
                    value: _useKds,
                    activeColor: AppColors.brandPrimary,
                    onChanged: (val) => _updateSettings(val, _useOrders, _enableInventory),
                  ),
                ),
                SettingsDivider(isDark: isDark),
                SettingsRow(
                  isDark: isDark,
                  title: 'Показывать вкладку Заказы',
                  subtitle: 'Отображать вкладку с активными заказами на экране кассы',
                  trailing: Switch(
                    value: _useOrders,
                    activeColor: AppColors.brandPrimary,
                    onChanged: (val) => _updateSettings(_useKds, val, _enableInventory),
                  ),
                ),
                SettingsDivider(isDark: isDark),
                SettingsRow(
                  isDark: isDark,
                  title: 'Списание ингредиентов',
                  subtitle: 'Минусовать сырье по тех. картам при продаже',
                  trailing: Switch(
                    value: _enableInventory,
                    activeColor: AppColors.brandPrimary,
                    onChanged: (val) => _updateSettings(_useKds, _useOrders, val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            buildSettingsHeader('Внешний вид', isDark),
            const SizedBox(height: 32),
            SettingsCard(
              isDark: isDark,
              children: [
                SettingsRow(
                  isDark: isDark,
                  title: 'Цветовая схема (Тема)',
                  subtitle: 'Выбор светлой или темной темы',
                  trailing: BlocBuilder<ThemeBloc, ThemeMode>(
                    builder: (context, themeMode) {
                      final themes = [
                        {'label': 'Светлая (Basic)', 'mode': ThemeMode.light, 'variant': 'basic'},
                        {'label': 'Светлая (Cream)', 'mode': ThemeMode.light, 'variant': 'soft_cream'},
                        {'label': 'Светлая (Contrast)', 'mode': ThemeMode.light, 'variant': 'high_contrast_light'},
                        {'label': 'Темная (Ember)', 'mode': ThemeMode.dark, 'variant': 'basic'},
                        {'label': 'Темная (Deep Ocean)', 'mode': ThemeMode.dark, 'variant': 'deep_ocean'},
                      ];
                      
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: themes.map((t) {
                          final isSelected = themeMode == t['mode'] && state.themeVariant == t['variant'];
                          return _buildThemeVariantBtn(
                            context,
                            isDark: isDark,
                            label: t['label'] as String,
                            isSelected: isSelected,
                            onTap: () {
                              context.read<SettingsBloc>().add(UpdateThemeVariant(t['variant'] as String));
                              if (themeMode != t['mode']) {
                                context.read<ThemeBloc>().add(ThemeEvent.toggleTheme);
                              }
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            buildSettingsHeader('Региональные настройки', isDark),
            const SizedBox(height: 32),
            SettingsCard(
              isDark: isDark,
              children: [
                SettingsRow(
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
                SettingsDivider(isDark: isDark),
                SettingsRow(
                  isDark: isDark,
                  title: 'Часовой пояс',
                  subtitle: 'Определяет время чеков и смен',
                  trailing: DropdownStub(isDark: isDark, value: 'GMT+3 (Москва)'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            buildSettingsHeader('Системные настройки', isDark),
            const SizedBox(height: 32),
            SettingsCard(
              isDark: isDark,
              children: [
                SettingsRow(
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
          color: isSelected ? AppColors.brandPrimary.withOpacity(0.15) : (isDark ? AppColors.darkBg : AppColors.lightBg),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
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
          color: isSelected ? AppColors.brandPrimary.withOpacity(0.15) : (isDark ? AppColors.darkBg : AppColors.lightBg),
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
              style: TextStyle(
                color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
