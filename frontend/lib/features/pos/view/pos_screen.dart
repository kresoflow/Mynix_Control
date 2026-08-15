import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';

import 'package:mynix_frontend/core/widgets/responsive_layout.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
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
import 'widgets/x_report_modal.dart';
import 'widgets/close_shift_modal.dart';

import 'package:mynix_frontend/features/orders/view/orders_screen.dart';
import 'package:mynix_frontend/features/kitchen/view/kitchen_screen.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
          final msg = diff == 0 
              ? 'Смена закрыта успешно. Расхождений нет.' 
              : 'Смена закрыта. Недостача/излишек: ${(diff as num).toCurrency(context)}';
          _showSnackbar(context, msg, diff == 0 ? AppColors.success : AppColors.warning);
        } else if (state is ShiftError) {
          _showSnackbar(context, state.message, AppColors.danger);
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
                  // Sub-tab Navigation Header
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
                        const Spacer(),

                        // Action Buttons: X-Report & Close Shift
                        IconButton(
                          tooltip: 'X-Отчет (Текущая статистика)',
                          icon: Icon(PhosphorIconsRegular.chartPie, color: AppColors.brandPrimary),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const XReportModal(),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton.icon(
                          onPressed: () {
                            final expected = (state as ShiftOpen).shiftDetails['current_cash_expected'] ?? 0.0;
                            showDialog(
                              context: context,
                              builder: (context) => CloseShiftModal(
                                expectedCash: (expected as num).toDouble(),
                              ),
                            );
                          },
                          icon: Icon(PhosphorIconsRegular.lockKey, size: 16, color: AppColors.danger),
                          label: Text(
                            'Закрыть смену',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.danger),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
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

  void _showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.width < 768 ? 100 : 24,
          left: 16,
          right: 16,
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
        _showSnackbar(context, '${parent.cleanName} (${child.cleanName}) добавлен', AppColors.success);
        return;
      }
    }

    final item = menuState.items.where((i) => i.barcode == barcode).firstOrNull;
    if (item != null) {
      context.read<CartBloc>().add(AddItemToCart(item));
      _showSnackbar(context, '${item.cleanName} добавлен', AppColors.success);
    } else {
      _showSnackbar(context, 'Товар со штрихкодом не найден', const Color(0xFFF59E0B));
    }
  }
}
