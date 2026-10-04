// ==============================================================================
// МОДУЛЬ: POS / Главный экран рабочего места кассира (PosScreen)
// ДОМЕН: lib/features/pos/view/pos_screen.dart
// ==============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/utils/audio_helper.dart';
import 'package:kreso_frontend/core/network/websocket_service.dart';

import 'package:kreso_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_event.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_state.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_nav_cubit.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_tab_cubit.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:kreso_frontend/features/orders/bloc/orders_bloc.dart';
import 'package:kreso_frontend/features/orders/view/orders_screen.dart';
import 'package:kreso_frontend/features/kitchen/view/kitchen_screen.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_state.dart';

import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

import 'widgets/pos_mobile_layout.dart';
import 'widgets/pos_desktop_layout.dart';
import 'widgets/open_shift_modal.dart';
import 'widgets/barcode_scanner_listener.dart';

// ── Главный экран кассы ───────────────────────────────────────────────────────

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  StreamSubscription? _wsSubscription;
  Timer? _refreshTimer;
  Timer? _ordersShiftTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<MenuBloc>().state is! MenuLoaded) {
        context.read<MenuBloc>().add(LoadMenu());
      }
      if (context.read<CategoryBloc>().state is! CategoryLoaded) {
        context.read<CategoryBloc>().add(LoadCategories());
      }
      if (context.read<ShiftBloc>().state is ShiftInitial) {
        context.read<ShiftBloc>().add(CheckCurrentShift());
      }
      context.read<PosTabCubit>().refreshCounts();
      _initIncomingOrders();
    });
  }

  void _debouncedRefreshCounts() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _refreshCounts();
    });
  }

  void _debouncedUpdateOrdersAndShift() {
    _ordersShiftTimer?.cancel();
    _ordersShiftTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _updateOrdersAndShift();
    });
  }

  void _initIncomingOrders() {
    _wsSubscription = webSocketService.messages.listen((msg) {
      if (!mounted) return;
      final event = msg['event'];
      final authState = context.read<AuthBloc>().state;
      final isWaiter = authState is AuthAuthenticated && authState.role.toLowerCase() == 'waiter';

      if (event == 'incoming_order') {
        _debouncedRefreshCounts();
        if (!isWaiter) {
          AudioHelper.playNewOrderSound();
          final order = msg['order'] ?? {};
          final table = order['table_number'] ?? 'Зал';
          if (mounted) {
            AppToast.showInfo(context, 'Новый заказ с зала', subtitle: '$table (нажмите на колокольчик)');
          }
        }
      } else if (event == 'incoming_order_resolved') {
        _debouncedRefreshCounts();
        final order = msg['order'] ?? {};
        final orderNum = order['order_number'] ?? order['id'] ?? '';
        final status = order['status']?.toString().toUpperCase();
        if (mounted) {
          if (isWaiter) {
            if (status == 'CANCELLED' || status == 'REJECTED') {
              AppToast.showWarning(context, 'Заказ #$orderNum отклонен', subtitle: 'Кассир отклонил заказ');
            } else {
              AppToast.showSuccess(context, 'Заказ #$orderNum принят', subtitle: 'Кассир подтвердил заказ');
            }
          }
          _debouncedUpdateOrdersAndShift();
        }
      } else if (event == 'status_update') {
        _debouncedRefreshCounts();
        final orderId = msg['order_id'];
        final status = msg['status']?.toString().toUpperCase();
        if (mounted) {
          if (status == 'READY') {
            AppToast.showSuccess(context, 'Заказ готов к выдаче!', subtitle: 'Заказ #$orderId');
          }
          _debouncedUpdateOrdersAndShift();
        }
      } else if (event == 'new_order') {
        _debouncedRefreshCounts();
        if (mounted) {
          _debouncedUpdateOrdersAndShift();
        }
      }
    });
  }

  void _updateOrdersAndShift() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0).toUtc().toIso8601String();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc().toIso8601String();
    context.read<OrdersBloc>().add(LoadOrders(startDate: startOfToday, endDate: endOfToday));
    context.read<ShiftBloc>().add(CheckCurrentShift());
    _refreshCounts();
  }

  void _refreshCounts() {
    if (mounted) {
      context.read<PosTabCubit>().refreshCounts();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _ordersShiftTimer?.cancel();
    _wsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final useOrders = settingsState.useOrders;
    final useKds = settingsState.useKds;
    final currentTab = context.watch<PosTabCubit>().state.currentTab;

    if (currentTab == 1 && !useOrders) {
      context.read<PosTabCubit>().setTab(0);
    }
    if (currentTab == 2 && !useKds) {
      context.read<PosTabCubit>().setTab(0);
    }

    final isMobile = MediaQuery.of(context).size.width < 768;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final cartItems = context.read<CartBloc>().state.items;
        if (cartItems.isEmpty) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          return;
        }
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AppDialog(
            title: 'В чеке есть товары',
            icon: PhosphorIconsRegular.warning,
            isDestructive: true,
            width: 420,
            content: Text(
              'В текущем чеке ${cartItems.length} поз. При выходе чек будет сброшен. Вы действительно хотите покинуть кассу?',
              style: AppTextStyles.bodyMedium,
            ),
            actions: [
              AppGhostButton(
                label: 'Остаться в кассе',
                onPressed: () => Navigator.pop(ctx, false),
              ),
              AppDangerButton(
                label: 'Сбросить и выйти',
                icon: PhosphorIconsRegular.signOut,
                onPressed: () {
                  context.read<CartBloc>().add(ClearCart());
                  Navigator.pop(ctx, true);
                },
              ),
            ],
          ),
        );
        if (shouldLeave == true && context.mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },
      child: BlocListener<ShiftBloc, ShiftState>(
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
                : IndexedStack(
                    index: currentTab,
                    children: [
                      const PosDesktopLayout(),
                      if (useOrders) const OrdersScreen() else const SizedBox.shrink(),
                      if (useKds) const KitchenScreen() else const SizedBox.shrink(),
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
        context.read<CartBloc>().add(
          AddItemToCart(
            parent,
            selectedOptionsJson: jsonEncode({'variation': child.cleanName, 'child_item_id': child.id}),
            selectedOptionsPrice: child.price - parent.price,
          ),
        );
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
