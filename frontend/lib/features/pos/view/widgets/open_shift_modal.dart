import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_event.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'dart:ui';

void showOpenShiftDialog(BuildContext context) {
  final controller = TextEditingController();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (ctx) => MynixDialog(
      title: 'Открытие смены',
      icon: PhosphorIconsRegular.wallet,
      width: 400,
      actions: [
        AppButton.secondary(
          label: 'Отмена',
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        AppButton.primary(
          label: 'Открыть смену',
          onPressed: () {
            final amount = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
            context.read<ShiftBloc>().add(OpenShiftRequested(amount));
            Navigator.of(ctx).pop();
          },
        ),
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Внесите разменный фонд в кассу для начала смены:',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0.00',
              labelText: 'Разменный фонд (с)',
              prefixIcon: const Icon(PhosphorIconsRegular.money),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    ),
  );
}

class OpenShiftModal extends StatefulWidget {
  const OpenShiftModal({super.key});

  @override
  State<OpenShiftModal> createState() => _OpenShiftModalState();
}

class _OpenShiftModalState extends State<OpenShiftModal> with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Stack(
      children: [
        // Background blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPrimary.withValues(alpha: 0.15),
                      blurRadius: 60,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(PhosphorIconsRegular.wallet, size: 56, color: AppColors.brandPrimary),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Открытие смены',
                      style: AppTextStyles.h1.copyWith(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Внесите разменный фонд в кассу для начала рабочего дня.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: isDark ? AppColors.lightSubtext : AppColors.darkSubtext,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: AppTextStyles.h2.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        labelText: 'Разменный фонд (с)',
                        labelStyle: AppTextStyles.body.copyWith(color: AppColors.brandPrimary),
                        filled: true,
                        fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: AppColors.brandPrimary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: () {
                          final amount = double.tryParse(_amountController.text) ?? 0.0;
                          context.read<ShiftBloc>().add(OpenShiftRequested(amount));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: AppColors.brandPrimary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(
                          'ОТКРЫТЬ СМЕНУ',
                          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
