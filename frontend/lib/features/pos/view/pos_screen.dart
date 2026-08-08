import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/widgets/responsive_layout.dart';
import 'package:mynix_frontend/features/pos/view/widgets/pos_menu_grid.dart';
import 'dart:convert';
import 'package:mynix_frontend/features/pos/view/widgets/pos_cart.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_event.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_state.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_nav_cubit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/features/pos/view/widgets/barcode_scanner_listener.dart';


class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ShiftBloc, ShiftState>(
      listener: (context, state) {
        if (state is ShiftClosedSuccessfully) {
          final diff = state.report['discrepancy'] ?? 0;
          final msg = diff == 0 
              ? 'Смена закрыта успешно. Расхождений нет.' 
              : 'Смена закрыта. Недостача/излишек: ${(diff as num).toCurrency(context)}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: diff == 0 ? AppColors.success : AppColors.warning,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.width < 768 ? 100 : 24,
                left: 16,
                right: 16,
              ),
            ),
          );
        } else if (state is ShiftError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.width < 768 ? 100 : 24,
                left: 16,
                right: 16,
              ),
            ),
          );
        }
      },
      child: BlocBuilder<ShiftBloc, ShiftState>(
        builder: (context, state) {
          if (state is ShiftLoading || state is ShiftInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ShiftClosed) {
            return const _OpenShiftScreen();
          }

          return BlocProvider(
            create: (context) => PosNavCubit(),
            child: BarcodeScannerListener(
              onBarcodeScanned: (barcode) {
                final menuState = context.read<MenuBloc>().state;
                if (menuState is MenuLoaded) {
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${parent.cleanName} (${child.cleanName}) добавлен'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.width < 768 ? 100 : 24,
                            left: 16,
                            right: 16,
                          ),
                        ),
                      );
                      return;
                    }
                  }

                  final item = menuState.items.where((i) => i.barcode == barcode).firstOrNull;
                  if (item != null) {
                    context.read<CartBloc>().add(AddItemToCart(item));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.cleanName} добавлен'),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.width < 768 ? 100 : 24,
                          left: 16,
                          right: 16,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Товар со штрихкодом не найден'),
                        backgroundColor: Color(0xFFF59E0B),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.width < 768 ? 100 : 24,
                          left: 16,
                          right: 16,
                        ),
                      ),
                    );
                  }
                }
              },
              child: const ResponsiveLayout(
                mobile: _MobileLayout(),
                tablet: _TabletLayout(),
                desktop: _DesktopLayout(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OpenShiftScreen extends StatefulWidget {
  const _OpenShiftScreen();

  @override
  State<_OpenShiftScreen> createState() => _OpenShiftScreenState();
}

class _OpenShiftScreenState extends State<_OpenShiftScreen> {
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.lock, size: 64, color: theme.colorScheme.primary),
            SizedBox(height: 24),
            Text(
              'Смена закрыта',
              style: AppTextStyles.h1,
            ),
            const SizedBox(height: 8),
            Text(
              'Для начала работы с кассой необходимо открыть смену и внести разменные деньги.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.lightSubtext),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.h2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Разменные деньги (с)',
                prefixIcon: Icon(PhosphorIconsRegular.wallet),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(_amountController.text) ?? 0.0;
                  context.read<ShiftBloc>().add(OpenShiftRequested(amount));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  textStyle: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                child: const Text('ОТКРЫТЬ СМЕНУ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: PosMenuGrid(),
        ),
        BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            final itemCount = state.items.fold(0, (sum, item) => sum + item.quantity);
            if (itemCount == 0) return const SizedBox.shrink();

            return Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => BlocListener<CartBloc, CartState>(
                        listenWhen: (previous, current) => !previous.submitSuccess && current.submitSuccess,
                        listener: (context, state) {
                          if (state.submitSuccess) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.85,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: const ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            child: PosCart(),
                          ),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: AppColors.brandPrimary.withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$itemCount',
                          style: AppTextStyles.h3.copyWith(color: Colors.white),
                        ),
                      ),
                      Text('Корзина', style: AppTextStyles.h3.copyWith(color: Colors.white)),
                      Text(
                        state.total.toCurrency(context),
                        style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TabletLayout extends StatelessWidget {
  const _TabletLayout();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 6, child: PosMenuGrid()),
        Expanded(flex: 4, child: PosCart()),
      ],
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 6, child: PosMenuGrid()),
        Expanded(flex: 4, child: PosCart()),
      ],
    );
  }
}
