import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/theme_bloc.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка сохранения настроек')));
      }
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
                    activeThumbColor: AppColors.brandPrimary,
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
                    activeThumbColor: AppColors.brandPrimary,
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
                    activeThumbColor: AppColors.brandPrimary,
                    onChanged: (val) => _updateSettings(_useKds, _useOrders, val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            buildSettingsHeader('Внешний вид', isDark),
            const SizedBox(height: 32),
            BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, themeState) {
                return SettingsCard(
                  isDark: isDark,
                  children: [
                    SettingsRow(
                      isDark: isDark,
                      title: 'Режим отображения',
                      subtitle: 'Переключение между светлым и тёмным интерфейсом',
                      trailing: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildModeBtn(
                            context,
                            isDark: isDark,
                            label: 'Светлый',
                            icon: PhosphorIconsRegular.sun,
                            isSelected: themeState.mode == ThemeMode.light,
                            onTap: () => context.read<ThemeBloc>().add(const SetThemeMode(ThemeMode.light)),
                          ),
                          _buildModeBtn(
                            context,
                            isDark: isDark,
                            label: 'Тёмный',
                            icon: PhosphorIconsRegular.moon,
                            isSelected: themeState.mode == ThemeMode.dark,
                            onTap: () => context.read<ThemeBloc>().add(const SetThemeMode(ThemeMode.dark)),
                          ),
                          _buildModeBtn(
                            context,
                            isDark: isDark,
                            label: 'Системный',
                            icon: PhosphorIconsRegular.desktop,
                            isSelected: themeState.mode == ThemeMode.system,
                            onTap: () => context.read<ThemeBloc>().add(const SetThemeMode(ThemeMode.system)),
                          ),
                        ],
                      ),
                    ),
                    SettingsDivider(isDark: isDark),
                    SettingsRow(
                      isDark: isDark,
                      title: 'Цветовой стиль бренда',
                      subtitle: 'Гармоничная палитра акцентов и поверхностей',
                      trailing: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPaletteBtn(
                            context,
                            isDark: isDark,
                            label: 'Ember (Янтарь)',
                            accentColor: const Color(0xFFE8A020),
                            isSelected: themeState.palette == ThemePalette.ember,
                            onTap: () => context.read<ThemeBloc>().add(const SetThemePalette(ThemePalette.ember)),
                          ),
                          _buildPaletteBtn(
                            context,
                            isDark: isDark,
                            label: 'Deep Ocean (Океан)',
                            accentColor: const Color(0xFF00F0FF),
                            isSelected: themeState.palette == ThemePalette.ocean,
                            onTap: () => context.read<ThemeBloc>().add(const SetThemePalette(ThemePalette.ocean)),
                          ),
                          _buildPaletteBtn(
                            context,
                            isDark: isDark,
                            label: 'Soft Cream (Крем)',
                            accentColor: const Color(0xFFD97706),
                            isSelected: themeState.palette == ThemePalette.cream,
                            onTap: () => context.read<ThemeBloc>().add(const SetThemePalette(ThemePalette.cream)),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
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

  Widget _buildModeBtn(
    BuildContext context, {
    required bool isDark,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final brand = isDark ? AppColors.brandPrimary : AppColors.lightPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? brand.withValues(alpha: 0.15) : (isDark ? AppColors.darkBg : AppColors.lightBg),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? brand : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? brand : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? brand : (isDark ? AppColors.darkText : AppColors.lightText),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteBtn(
    BuildContext context, {
    required bool isDark,
    required String label,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final brand = isDark ? AppColors.brandPrimary : AppColors.lightPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? brand.withValues(alpha: 0.15) : (isDark ? AppColors.darkBg : AppColors.lightBg),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? brand : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: isSelected ? [BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 6)] : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? brand : (isDark ? AppColors.darkText : AppColors.lightText),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyBtn(BuildContext context, bool isDark, SettingsState state, String code, String name) {
    final isSelected = state.currency == code;
    final brand = isDark ? AppColors.brandPrimary : AppColors.lightPrimary;
    return InkWell(
      onTap: () {
        context.read<SettingsBloc>().add(UpdateCurrency(code));
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? brand.withValues(alpha: 0.15) : (isDark ? AppColors.darkBg : AppColors.lightBg),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? brand : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? brand : (isDark ? AppColors.darkText : AppColors.lightText),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? brand : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
