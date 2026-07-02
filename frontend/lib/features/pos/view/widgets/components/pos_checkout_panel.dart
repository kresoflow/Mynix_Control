import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';

class PosCheckoutPanel extends StatelessWidget {
  const PosCheckoutPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
      ),
      child: BlocConsumer<CartBloc, CartState>(
        listenWhen: (previous, current) =>
            previous.submitSuccess != current.submitSuccess ||
            previous.submitError != current.submitError,
        listener: (context, state) {
          if (state.submitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✓ Заказ успешно создан')),
            );
          } else if (state.submitError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка: ${state.submitError}'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Subtotal row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Итого',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.darkSubtext)),
                  Text(
                    state.total.toCurrency(context),
                    style: AppTextStyles.priceLarge.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Charge button
              AppPrimaryButton(
                label: state.isSubmitting 
                    ? 'ОБРАБОТКА...'
                    : (state.items.isEmpty
                        ? 'ОПЛАТИТЬ'
                        : 'ОПЛАТИТЬ — ${state.total.toCurrency(context)}'),
                height: 60,
                onPressed: state.items.isEmpty || state.isSubmitting
                    ? null
                    : () {
                        context.read<CartBloc>().add(const CheckoutCart());
                      },
              ),
            ],
          );
        },
      ),
    );
  }
}
