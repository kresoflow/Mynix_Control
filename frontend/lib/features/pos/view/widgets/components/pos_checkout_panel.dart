import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';

class PosCheckoutPanel extends StatefulWidget {
  const PosCheckoutPanel({super.key});

  @override
  State<PosCheckoutPanel> createState() => _PosCheckoutPanelState();
}

class _PosCheckoutPanelState extends State<PosCheckoutPanel> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  String _selectedPaymentMethod = 'CASH'; // 'CASH' or 'TRANSFER'

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, isMobile ? 16 : 24, isMobile ? 16 : 24, isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -10),
            blurRadius: 20,
          )
        ],
      ),
      child: BlocConsumer<CartBloc, CartState>(
        listenWhen: (previous, current) =>
            (!previous.submitSuccess && current.submitSuccess) ||
            (previous.submitError != current.submitError && current.submitError != null),
        listener: (context, state) {
          if (state.submitSuccess) {
            AppToast.showSuccess(
              context,
              'Заказ успешно оплачен',
              subtitle: 'Чек сохранен в истории',
            );
          } else if (state.submitError != null) {
            AppToast.showError(
              context,
              'Ошибка оформления заказа',
              subtitle: state.submitError!.replaceAll('Exception: ', ''),
            );
          }
        },
        builder: (context, state) {
          final isEmpty = state.items.isEmpty;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Payment method selector
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentOption(
                      method: 'CASH',
                      label: 'Наличные',
                      icon: PhosphorIconsRegular.money,
                      isSelected: _selectedPaymentMethod == 'CASH',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPaymentOption(
                      method: 'TRANSFER',
                      label: 'Перевод',
                      icon: PhosphorIconsRegular.qrCode,
                      isSelected: _selectedPaymentMethod == 'TRANSFER',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Subtotal row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'К оплате',
                    style: AppTextStyles.h2.copyWith(
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    state.total.toCurrency(context),
                    style: AppTextStyles.h1.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 24 : 32,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 20),
              
              // Standardized checkout button
              ScaleTransition(
                scale: isEmpty ? const AlwaysStoppedAnimation(1.0) : _scaleAnimation,
                child: AppButton.primary(
                  label: state.isSubmitting
                      ? 'Обработка...'
                      : 'Оплатить (${_selectedPaymentMethod == 'CASH' ? 'Наличные' : 'Перевод'})',
                  icon: _selectedPaymentMethod == 'CASH' ? PhosphorIconsRegular.money : PhosphorIconsRegular.qrCode,
                  isFullWidth: true,
                  height: 48,
                  isLoading: state.isSubmitting,
                  onPressed: isEmpty || state.isSubmitting
                      ? null
                      : () {
                          context.read<CartBloc>().add(
                            CheckoutCart(paymentMethod: _selectedPaymentMethod),
                          );
                        },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentOption({
    required String method,
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
  }) {
    final activeColor = AppColors.brandPrimary;
    final inactiveColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? activeColor.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected 
                ? activeColor 
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? activeColor : inactiveColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
