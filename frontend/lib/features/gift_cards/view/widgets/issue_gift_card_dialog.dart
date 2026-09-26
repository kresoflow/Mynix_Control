// ==============================================================================
// МОДУЛЬ: Подарочные карты (Gift Cards)
// ДОМЕН: lib/features/gift_cards/view/widgets/issue_gift_card_dialog.dart
// ==============================================================================
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog_scaffold.dart';
import 'package:kreso_frontend/core/widgets/app_text_field.dart';
import 'package:kreso_frontend/core/widgets/app_toast.dart';
import 'package:kreso_frontend/features/gift_cards/bloc/gift_card_bloc.dart';
import 'package:kreso_frontend/features/gift_cards/repository/gift_card_repository.dart';
import 'package:kreso_frontend/features/gift_cards/view/widgets/gift_card_preview_card.dart';

/// Модальное окно эмиссии новой подарочной карты.
/// 
/// [UI-KIT] Использует AppDialogScaffold, шкалу AppButtonSize и токены AppTextStyles.
/// [ИНВАРИАНТ] Запрещено выпускать карту с нулевым или отрицательным номиналом.
class IssueGiftCardDialog extends StatefulWidget {
  final int? customerId;

  const IssueGiftCardDialog({super.key, this.customerId});

  static Future<void> show(BuildContext context, {int? customerId}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        try {
          final bloc = context.read<GiftCardBloc>();
          return BlocProvider.value(
            value: bloc,
            child: IssueGiftCardDialog(customerId: customerId),
          );
        } catch (_) {
          return BlocProvider(
            create: (_) => GiftCardBloc(repository: GiftCardRepository()),
            child: IssueGiftCardDialog(customerId: customerId),
          );
        }
      },
    );
  }

  @override
  State<IssueGiftCardDialog> createState() => _IssueGiftCardDialogState();
}

class _IssueGiftCardDialogState extends State<IssueGiftCardDialog> {
  // ─── 1. Контроллеры и состояние ─────────────────────────────────────────────
  late final TextEditingController _amountController;
  late final TextEditingController _codeController;
  late final TextEditingController _notesController;
  double _selectedAmount = 1000.0;
  int _selectedMonthsValidity = 12;
  String? _amountError;

  static const List<double> _predefinedNominals = [500, 1000, 2000, 5000, 10000];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: _selectedAmount.toStringAsFixed(0));
    _codeController = TextEditingController(text: _generateRandomCode());
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _codeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _generateRandomCode() {
    final rand = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final p1 = List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    final p2 = List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'GC-$p1-$p2';
  }

  void _onNominalSelected(double nominal) {
    setState(() {
      _selectedAmount = nominal;
      _amountController.text = nominal.toStringAsFixed(0);
      _amountError = null;
    });
  }

  void _onAmountChanged(String val) {
    final parsed = double.tryParse(val.replaceAll(' ', ''));
    setState(() {
      if (parsed != null && parsed > 0) {
        _selectedAmount = parsed;
        _amountError = null;
      } else {
        _selectedAmount = 0.0;
        _amountError = 'Укажите корректную сумму';
      }
    });
  }

  DateTime? get _calculatedExpiryDate {
    if (_selectedMonthsValidity <= 0) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month + _selectedMonthsValidity, now.day);
  }

  void _onSubmit(BuildContext context) {
    if (_selectedAmount <= 0) {
      setState(() => _amountError = 'Номинал должен быть больше нуля');
      return;
    }
    context.read<GiftCardBloc>().add(IssueGiftCardEvent(
      code: _codeController.text.trim().toUpperCase(),
      initialBalance: _selectedAmount,
      expiryDate: _calculatedExpiryDate,
        customerId: widget.customerId,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      ),);
  }

  // ─── 2. Верстка интерфейса ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GiftCardBloc, GiftCardState>(
      listener: (context, state) {
        if (state.status == GiftCardStateStatus.actionSuccess) {
          AppToast.showSuccess(context, state.actionMessage ?? 'Подарочная карта успешно выпущена');
          Navigator.of(context).pop();
        } else if (state.status == GiftCardStateStatus.failure && state.errorMessage != null) {
          AppToast.showError(context, 'Ошибка выпуска карты', subtitle: state.errorMessage);
        }
      },
      builder: (context, state) {
        return AppDialogScaffold(
          title: 'Выпуск подарочной карты',
          subtitle: 'Эмиссия сертификата с балансом и уникальным кодом',
          icon: PhosphorIconsRegular.gift,
          maxWidth: 560,
          maxHeight: 700,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GiftCardPreviewCard(
                  amount: _selectedAmount,
                  code: _codeController.text,
                  monthsValidity: _selectedMonthsValidity,
                  expiryDate: _calculatedExpiryDate,
                ),
                const SizedBox(height: 20),
                Text('Выберите номинал карты', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _predefinedNominals.map((nom) => AppSecondaryButton(
                    label: nom.toCurrency(context),
                    size: AppButtonSize.sm,
                    isSelected: (_selectedAmount - nom).abs() < 0.01,
                    onPressed: () => _onNominalSelected(nom),
                  ),).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: AppTextField(
                        controller: _amountController,
                        labelText: 'Номинал (${CurrencyFormatter.symbol(context)})',
                        hintText: '1000',
                        keyboardType: TextInputType.number,
                        errorText: _amountError,
                        onChanged: _onAmountChanged,
                        prefixIcon: const Icon(PhosphorIconsRegular.money, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: AppTextField(
                        controller: _codeController,
                        labelText: 'Код карты',
                        hintText: 'GC-XXXX-XXXX',
                        prefixIcon: const Icon(PhosphorIconsRegular.barcode, size: 18),
                        suffixIcon: IconButton(
                          icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 16),
                          tooltip: 'Сгенерировать код',
                          onPressed: () => setState(() => _codeController.text = _generateRandomCode()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Срок действия', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildValidityChip('3 месяца', 3),
                    _buildValidityChip('6 месяцев', 6),
                    _buildValidityChip('1 год', 12),
                    _buildValidityChip('Бессрочно', 0),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _notesController,
                  labelText: 'Примечание или имя гостя (опционально)',
                  hintText: 'Например: Подарок к празднику',
                ),
              ],
            ),
          ),
          actions: [
            AppGhostButton(
              label: 'Отмена',
              size: AppButtonSize.lg,
              onPressed: state.isActionLoading ? null : () => Navigator.of(context).pop(),
            ),
            AppPrimaryButton(
              label: 'Выпустить карту',
              size: AppButtonSize.lg,
              icon: PhosphorIconsRegular.sparkle,
              isLoading: state.isActionLoading,
              onPressed: () => _onSubmit(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildValidityChip(String label, int months) {
    return AppSecondaryButton(
      label: label,
      size: AppButtonSize.xs,
      isSelected: _selectedMonthsValidity == months,
      onPressed: () => setState(() => _selectedMonthsValidity = months),
    );
  }
}
