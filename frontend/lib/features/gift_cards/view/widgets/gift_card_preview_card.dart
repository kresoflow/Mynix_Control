// ==============================================================================
// МОДУЛЬ: Подарочные карты (Gift Cards)
// ДОМЕН: lib/features/gift_cards/view/widgets/gift_card_preview_card.dart
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';

/// Интерактивная визуальная карточка предпросмотра подарочной карты.
/// 
/// [UI-KIT] Использует токены AppColors.brandGradient, AppRadii и AppTextStyles.
class GiftCardPreviewCard extends StatelessWidget {
  final double amount;
  final String code;
  final int monthsValidity;
  final DateTime? expiryDate;

  const GiftCardPreviewCard({
    super.key,
    required this.amount,
    required this.code,
    required this.monthsValidity,
    this.expiryDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: AppRadii.cardRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(PhosphorIconsRegular.gift, color: AppColors.pureWhite, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'KRESO FLOW GIFT',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.pureWhite,
                      letterSpacing: 1.2,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite.withValues(alpha: 0.2),
                  borderRadius: AppRadii.pillRadius,
                ),
                child: Text(
                  monthsValidity == 0 ? 'БЕССРОЧНАЯ' : '$monthsValidity МЕСЯЦЕВ',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Баланс сертификата',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.pureWhite.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                amount.toCurrency(context),
                style: AppTextStyles.priceLarge.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                code.isEmpty ? 'GC-••••-••••' : code,
                style: AppTextStyles.price.copyWith(
                  color: AppColors.pureWhite.withValues(alpha: 0.9),
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                expiryDate == null
                    ? 'БЕЗ ОГРАНИЧЕНИЯ'
                    : 'ДО ${expiryDate!.day.toString().padLeft(2, '0')}.${expiryDate!.month.toString().padLeft(2, '0')}.${expiryDate!.year}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.pureWhite.withValues(alpha: 0.75),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
