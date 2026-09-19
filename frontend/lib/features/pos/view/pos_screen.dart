import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/utils/audio_helper.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/core/network/websocket_service.dart';


import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_event.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_state.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_nav_cubit.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/features/pos/repository/order_repository.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/features/orders/bloc/orders_bloc.dart';
import 'package:mynix_frontend/features/orders/view/orders_screen.dart';
import 'package:mynix_frontend/features/kitchen/view/kitchen_screen.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';

import 'package:mynix_frontend/core/widgets/ui_kit/ui_kit.dart';

import 'widgets/pos_mobile_layout.dart';
import 'widgets/pos_desktop_layout.dart';
import 'widgets/open_shift_modal.dart';
import 'widgets/barcode_scanner_listener.dart';
import 'widgets/dialogs/incoming_orders_dialog.dart';
import 'widgets/tables/pos_active_tables_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final OrderRepository _orderRepo = OrderRepository(apiClient.dio);
  int _currentTab = 0; // 0: POS, 1: Orders, 2: KDS Kitchen
  int _incomingCount = 0;
  int _activeTablesCount = 0;
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
    _refreshCounts();
    _wsSubscription = webSocketService.messages.listen((msg) {
      if (!mounted) return;
      final event = msg['event'];
      final authState = context.read<AuthBloc>().state;
      final isWaiter = authState is AuthAuthenticated && authState.role.toLowerCase() == 'waiter';

      if (event == 'incoming_order') {
        _refreshCounts();
        if (!isWaiter) {
          AudioHelper.playNewOrderSound();
          final order = msg['order'] ?? {};
          final table = order['table_number'] ?? 'Зал';
          if (mounted) {
            AppToast.showInfo(context, 'Новый заказ с зала', subtitle: '$table (нажмите на колокольчик)');
          }
        }
      } else if (event == 'incoming_order_resolved') {
        _refreshCounts();
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
          _updateOrdersAndShift();
        }
      } else if (event == 'status_update') {
        _refreshCounts();
        final orderId = msg['order_id'];
        final status = msg['status']?.toString().toUpperCase();
        if (mounted) {
          if (status == 'READY') {
            AppToast.showSuccess(context, 'Заказ готов к выдаче!', subtitle: 'Заказ #$orderId');
          }
          _updateOrdersAndShift();
        }
      } else if (event == 'new_order') {
        _refreshCounts();
        if (mounted) {
          _updateOrdersAndShift();
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
  }

  Future<void> _refreshCounts() async {
    try {
      final pending = await _orderRepo.fetchPendingOrders();
      final tables = await _orderRepo.fetchActiveTables();
      if (mounted) {
        setState(() {
          _incomingCount = pending.length;
          _activeTablesCount = tables.length;
        });
      }
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
          builder: (ctx) => MynixDialog(
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
                          AppSegmentedControl<int>(
                            selectedValue: _currentTab,
                            onValueChanged: (val) => setState(() => _currentTab = val),
                            size: AppSegmentedSize.md,
                            items: [
                              const AppSegmentedItem(value: 0, label: 'Касса', icon: PhosphorIconsRegular.receipt),
                              if (useOrders)
                                const AppSegmentedItem(value: 1, label: 'Заказы', icon: PhosphorIconsRegular.listNumbers),
                              if (useKds)
                                const AppSegmentedItem(value: 2, label: 'Кухня (KDS)', icon: PhosphorIconsRegular.cookingPot),
                            ],
                          ),
                          const Spacer(),
                          _buildActiveTablesBadge(isDark),
                          const SizedBox(width: 8),
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
    ),
  );
  }

  Widget _buildActiveTablesBadge(bool isDark) {
    final hasTables = _activeTablesCount > 0;
    final primary = AppColors.brandPrimary;
    final bg = hasTables
        ? primary.withValues(alpha: isDark ? 0.16 : 0.12)
        : (isDark ? AppColors.darkCard : AppColors.lightCard);
    final borderColor = hasTables
        ? primary.withValues(alpha: isDark ? 0.5 : 0.6)
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final fg = hasTables
        ? (isDark ? AppColors.darkText : primary)
        : (isDark ? AppColors.darkText : AppColors.lightText);
    final iconColor = hasTables ? primary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);

    return InkWell(
      onTap: () => PosActiveTablesDialog.show(context).then((_) => _refreshCounts()),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasTables ? PhosphorIconsBold.chair : PhosphorIconsRegular.chair,
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              'Столики ($_activeTablesCount)',
              style: TextStyle(
                color: fg,
                fontWeight: hasTables ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingOrdersBadge(bool isDark) {
    final authState = context.watch<AuthBloc>().state;
    final isWaiter = authState is AuthAuthenticated && authState.role.toLowerCase() == 'waiter';
    final hasPending = _incomingCount > 0;
    final badgeColor = isWaiter ? AppColors.brandPrimary : AppColors.warning;
    final label = isWaiter ? 'Мои заказы ($_incomingCount)' : 'Входящие ($_incomingCount)';
    final icon = isWaiter
        ? (hasPending ? PhosphorIconsBold.receipt : PhosphorIconsRegular.receipt)
        : (hasPending ? PhosphorIconsBold.bellRinging : PhosphorIconsRegular.bell);

    final bg = hasPending
        ? badgeColor.withValues(alpha: isDark ? 0.16 : 0.12)
        : (isDark ? AppColors.darkCard : AppColors.lightCard);
    final borderColor = hasPending
        ? badgeColor.withValues(alpha: isDark ? 0.5 : 0.6)
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final fg = hasPending
        ? (isDark ? AppColors.darkText : badgeColor)
        : (isDark ? AppColors.darkText : AppColors.lightText);
    final iconColor = hasPending ? badgeColor : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);

    return InkWell(
      onTap: () => IncomingOrdersDialog.show(context).then((_) => _refreshCounts()),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: hasPending ? FontWeight.w700 : FontWeight.w500,
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
