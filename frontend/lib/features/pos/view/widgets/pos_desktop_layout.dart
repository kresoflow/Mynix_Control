import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/view/widgets/pos_menu_grid.dart';
import 'package:mynix_frontend/features/pos/view/widgets/pos_cart.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_settings_cubit.dart';

class PosDesktopLayout extends StatelessWidget {
  const PosDesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosSettingsCubit, PosSettingsState>(
      builder: (context, settings) {
        final cartFlex = settings.cartWidthPercentage;
        final gridFlex = 100 - cartFlex;

        return Row(
          children: [
            Expanded(
              flex: gridFlex,
              child: const PosMenuGrid(),
            ),
            Container(
              width: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            ),
            Expanded(
              flex: cartFlex,
              child: ConstrainedBox(
                // Ограничиваем максимальную ширину корзины, 
                // чтобы при 50% на огромном мониторе она не была слишком гигантской
                constraints: const BoxConstraints(maxWidth: 650),
                child: const PosCart(),
              ),
            ),
          ],
        );
      },
    );
  }
}
