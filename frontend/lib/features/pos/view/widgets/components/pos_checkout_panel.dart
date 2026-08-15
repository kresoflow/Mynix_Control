import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';

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
    final bg = isDark ? const Color(0xFF1E2128) : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
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
            previous.submitSuccess != current.submitSuccess ||
            previous.submitError != current.submitError,
        listener: (context, state) {
          if (state.submitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✓ Заказ успешно создан'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.width < 768 ? 100 : 24,
                  left: 16,
                  right: 16,
                ),
              ),
            );
          } else if (state.submitError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка: ${state.submitError}'),
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
        builder: (context, state) {
          final isEmpty = state.items.isEmpty;
          
          return Column(
            children: [
              // Payment Method Selector (Cash vs Transfer)
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentOption(
                      method: 'CASH',
                      label: 'Наличные',
                      icon: Icons.payments_outlined,
                      isSelected: _selectedPaymentMethod == 'CASH',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPaymentOption(
                      method: 'TRANSFER',
                      label: 'Перевод',
                      icon: Icons.qr_code_scanner_rounded,
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
                  Text('К оплате',
                      style: AppTextStyles.h2.copyWith(
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          fontWeight: FontWeight.w600)),
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
              // Charge button with pulsing animation if not empty
              ScaleTransition(
                scale: isEmpty ? const AlwaysStoppedAnimation(1.0) : _scaleAnimation,
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: isEmpty || state.isSubmitting
                        ? null
                        : () {
                            context.read<CartBloc>().add(
                              CheckoutCart(paymentMethod: _selectedPaymentMethod),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEmpty 
                          ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05))
                          : AppColors.brandPrimary,
                      foregroundColor: isEmpty 
                          ? (isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.3))
                          : Colors.white,
                      elevation: isEmpty ? 0 : 12,
                      shadowColor: AppColors.brandPrimary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      state.isSubmitting 
                          ? 'ОБРАБОТКА...'
                          : 'ОПЛАТИТЬ (${_selectedPaymentMethod == 'CASH' ? 'НАЛИЧНЫЕ' : 'ПЕРЕВОД'})',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold, 
                        letterSpacing: 1.2,
                        fontSize: isMobile ? 13 : null,
                      ),
                    ),
                  ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? activeColor.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? activeColor 
                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
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
              style: TextStyle(
                color: isSelected ? (isDark ? Colors.white : Colors.black) : inactiveColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
