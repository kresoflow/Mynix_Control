import 'package:flutter/material.dart';
import 'package:retail_os_frontend/core/widgets/responsive_layout.dart';
import 'package:retail_os_frontend/features/pos/view/widgets/pos_menu_grid.dart';
import 'package:retail_os_frontend/features/pos/view/widgets/pos_cart.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:retail_os_frontend/features/pos/bloc/shift_event.dart';
import 'package:retail_os_frontend/features/pos/bloc/shift_state.dart';

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
              : 'Смена закрыта. Недостача/излишек: $diff с';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: diff == 0 ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        } else if (state is ShiftError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
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

          return Stack(
            children: [
              const ResponsiveLayout(
                mobile: _MobileLayout(),
                tablet: _TabletLayout(),
                desktop: _DesktopLayout(),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showCloseShiftDialog(context);
                  },
                  icon: const Icon(Icons.lock_clock),
                  label: const Text('Закрыть смену'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCloseShiftDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Закрытие смены'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Введите фактическую сумму наличных в кассе (Z-отчет):'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Сумма (с)',
                prefixIcon: Icon(Icons.payments),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              context.read<ShiftBloc>().add(CloseShiftRequested(amount));
              Navigator.pop(ctx);
              
              // We could show another dialog after closed to show discrepancy,
              // but ShiftBloc will change state to ShiftClosed and PosScreen will re-render
              // showing _OpenShiftScreen again.
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('ЗАКРЫТЬ'),
          ),
        ],
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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            const Text(
              'Смена закрыта',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Для начала работы с кассой необходимо открыть смену и внести разменные деньги.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 24),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Разменные деньги (с)',
                prefixIcon: Icon(Icons.account_balance_wallet),
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
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
    return const Column(
      children: [
        Expanded(flex: 1, child: PosMenuGrid()),
        Expanded(flex: 1, child: PosCart()),
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
