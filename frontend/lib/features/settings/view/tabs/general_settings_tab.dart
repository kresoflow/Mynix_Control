import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/features/settings/view/widgets/settings_ui_components.dart';
import 'package:mynix_frontend/features/settings/view/widgets/theme_appearance_settings_card.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';

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
        AppToast.showError(
          context,
          'Ошибка сохранения настроек',
          subtitle: e.toString(),
        );
      }
    }
  }

  Widget _buildCurrencyBtn(BuildContext context, bool isDark, SettingsState state, String symbol, String name) {
    final isSelected = state.currency == symbol;
    return InkWell(
      onTap: () => context.read<SettingsBloc>().add(UpdateCurrency(symbol)),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkBg : AppColors.lightBg),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
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
            ThemeAppearanceSettingsCard(isDark: isDark),
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
}
