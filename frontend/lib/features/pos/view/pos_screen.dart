import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';

import 'package:mynix_frontend/core/widgets/responsive_layout.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_state.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_nav_cubit.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/features/pos/view/widgets/barcode_scanner_listener.dart';

import 'widgets/pos_mobile_layout.dart';
import 'widgets/pos_desktop_layout.dart';
import 'widgets/open_shift_modal.dart';

import 'package:mynix_frontend/features/orders/view/orders_screen.dart';
import 'package:mynix_frontend/features/kitchen/view/kitchen_screen.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  int _currentTab = 0; // 0: POS, 1: Orders, 2: KDS Kitchen

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Listen to settings for feature toggles
    final settingsState = context.watch<SettingsBloc>().state;
    final useOrders = settingsState.useOrders;
    final useKds = settingsState.useKds;

    // Ensure _currentTab is valid if a tab was hidden
    if (_currentTab == 1 && !useOrders) _currentTab = 0;
    if (_currentTab == 2 && !useKds) _currentTab = 0;

    return BlocListener<ShiftBloc, ShiftState>(
      listener: (context, state) {
        if (state is ShiftClosedSuccessfully) {
          final diff = state.report['discrepancy'] ?? 0;
          if (diff == 0) {
            AppToast.showSuccess(context, 'Смена закрыта успешно', subtitle: 'Расхождений в кассе нет');
          } else {
            AppToast.showWarning(context, 'Смена закрыта', subtitle: 'Недостача/излишек: ${(diff as num).toCurrency(context)}');
          }
        } else if (state is ShiftError) {
          AppToast.showError(context, 'Ошибка смены', subtitle: state.message);
        }
      },
      child: BlocBuilder<ShiftBloc, ShiftState>(
        builder: (context, state) {
          if (state is ShiftLoading || state is ShiftInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ShiftClosed) {
            return const OpenShiftModal();
          }

          return BlocProvider(
            create: (context) => PosNavCubit(),
            child: BarcodeScannerListener(
              onBarcodeScanned: (barcode) => _handleBarcode(context, barcode),
              child: Column(
                children: [
                  // Sub-tab Navigation Header (only visible when there are alternative tabs to switch to)
                  if (useOrders || useKds)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton(0, 'Касса', PhosphorIconsRegular.receipt, isDark),
                          if (useOrders) ...[
                            const SizedBox(width: 8),
                            _buildTabButton(1, 'Заказы', PhosphorIconsRegular.listNumbers, isDark),
                          ],
                          if (useKds) ...[
                            const SizedBox(width: 8),
                            _buildTabButton(2, 'Кухня (KDS)', PhosphorIconsRegular.cookingPot, isDark),
                          ],
                        ],
                      ),
                    ),
                  // Active Screen View
                  Expanded(
                    child: IndexedStack(
                      index: _currentTab,
                      children: [
                        const ResponsiveLayout(
                          mobile: PosMobileLayout(),
                          tablet: PosDesktopLayout(),
                          desktop: PosDesktopLayout(),
                        ),
                        if (useOrders) const OrdersScreen() else const SizedBox.shrink(),
                        if (useKds) const KitchenScreen() else const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon, bool isDark) {
    final isSelected = _currentTab == index;
    final activeColor = AppColors.brandPrimary;
    final inactiveColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? activeColor.withValues(alpha: 0.15) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected 
              ? Border.all(color: activeColor.withValues(alpha: 0.4)) 
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBarcode(BuildContext context, String barcode) {
    final menuState = context.read<MenuBloc>().state;
    if (menuState is! MenuLoaded) return;

    final child = menuState.items.where((i) => i.barcode == barcode && i.parentId != null).firstOrNull;
    if (child != null) {
      final parent = menuState.items.where((i) => i.id == child.parentId).firstOrNull;
      if (parent != null) {
        context.read<CartBloc>().add(AddItemToCart(
          parent,
          selectedOptionsJson: jsonEncode({
            'variation': child.cleanName,
            'child_item_id': child.id,
          }),
          selectedOptionsPrice: child.price - parent.price,
        ));
        AppToast.showCart(context, '${parent.cleanName} (${child.cleanName})');
        return;
      }
    }

    final item = menuState.items.where((i) => i.barcode == barcode).firstOrNull;
    if (item != null) {
      context.read<CartBloc>().add(AddItemToCart(item));
      AppToast.showCart(context, item.cleanName);
    } else {
      AppToast.showWarning(context, 'Товар не найден', subtitle: 'Штрихкод: $barcode отсутствует в базе');
    }
  }
}
