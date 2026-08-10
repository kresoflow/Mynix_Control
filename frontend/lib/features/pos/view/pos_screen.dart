import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';

import 'package:mynix_frontend/core/widgets/responsive_layout.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_event.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_state.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_nav_cubit.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/features/pos/view/widgets/barcode_scanner_listener.dart';

import 'widgets/pos_mobile_layout.dart';
import 'widgets/pos_desktop_layout.dart';
import 'widgets/open_shift_modal.dart';

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
              child: const ResponsiveLayout(
                mobile: PosMobileLayout(),
                tablet: PosDesktopLayout(),
                desktop: PosDesktopLayout(),
              ),
            ),
          );
        },
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
