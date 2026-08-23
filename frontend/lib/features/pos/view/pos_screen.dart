import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/utils/audio_helper.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/core/network/websocket_service.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';

import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_event.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_state.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_nav_cubit.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/features/pos/repository/order_repository.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/features/orders/view/orders_screen.dart';
import 'package:mynix_frontend/features/kitchen/view/kitchen_screen.dart';

import 'widgets/pos_mobile_layout.dart';
import 'widgets/pos_desktop_layout.dart';
import 'widgets/open_shift_modal.dart';
import 'widgets/barcode_scanner_listener.dart';
import 'widgets/dialogs/incoming_orders_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final OrderRepository _orderRepo = OrderRepository(apiClient.dio);
  int _currentTab = 0; // 0: POS, 1: Orders, 2: KDS Kitchen
  int _incomingCount = 0;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuBloc>().add(LoadMenu());
      context.read<CategoryBloc>().add(LoadCategories());
      if (context.read<ShiftBloc>().state is ShiftInitial) {
        context.read<ShiftBloc>().add(CheckCurrentShift());
      }
      _initIncomingOrders();
    });
  }

  void _initIncomingOrders() {
    _refreshIncomingCount();
    _wsSubscription = webSocketService.messages.listen((msg) {
      final event = msg['event'];
      if (event == 'incoming_order') {
        AudioHelper.playNewOrderSound();
        _refreshIncomingCount();
        final order = msg['order'] ?? {};
        final table = order['table_number'] ?? 'Зал';
        AppToast.showInfo(context, 'Новый заказ с зала', subtitle: '$table (нажмите на колокольчик)');
      } else if (event == 'incoming_order_resolved') {
        _refreshIncomingCount();
      }
    });
  }

  Future<void> _refreshIncomingCount() async {
    try {
      final orders = await _orderRepo.fetchPendingOrders();
      if (mounted) setState(() => _incomingCount = orders.length);
    } catch (_) {}
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsState = context.watch<SettingsBloc>().state;
    final useOrders = settingsState.useOrders;
    final useKds = settingsState.useKds;

    if (_currentTab == 1 && !useOrders) _currentTab = 0;
    if (_currentTab == 2 && !useKds) _currentTab = 0;

    final isMobile = MediaQuery.of(context).size.width < 768;

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

          final posBody = isMobile
              ? const PosMobileLayout()
              : Column(
                  children: [
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
                          _buildIncomingOrdersBadge(isDark),
                        ],
                      ),
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _currentTab,
                        children: [
                          const PosDesktopLayout(),
                          if (useOrders) const OrdersScreen() else const SizedBox.shrink(),
                          if (useKds) const KitchenScreen() else const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ],
                );

          return BlocProvider(
            create: (context) => PosNavCubit(),
            child: BarcodeScannerListener(
              onBarcodeScanned: (barcode) => _handleBarcode(context, barcode),
              child: posBody,
            ),
          );
        },
      ),
    );
  }

  Widget _buildIncomingOrdersBadge(bool isDark) {
    final hasPending = _incomingCount > 0;
    return InkWell(
      onTap: () => IncomingOrdersDialog.show(context).then((_) => _refreshIncomingCount()),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: hasPending ? Colors.amber.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasPending ? Colors.amber.withValues(alpha: 0.6) : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasPending ? PhosphorIconsBold.bellRinging : PhosphorIconsRegular.bell,
              size: 17,
              color: hasPending ? Colors.amber : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
            const SizedBox(width: 6),
            Text(
              'Входящие ($_incomingCount)',
              style: TextStyle(
                color: hasPending ? Colors.amber : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                fontWeight: hasPending ? FontWeight.w800 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
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
          color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: activeColor.withValues(alpha: 0.4)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? activeColor : inactiveColor),
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
          selectedOptionsJson: jsonEncode({'variation': child.cleanName, 'child_item_id': child.id}),
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
