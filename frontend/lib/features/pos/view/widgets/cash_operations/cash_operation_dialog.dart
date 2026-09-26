// ==============================================================================
//  Kreso Flow — POS: Cash Operation Dialog
//  [UI-KIT] [ФИНАНСЫ] Диалог служебных внесений, расходов и инкассации.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/network/api_client.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_event.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_state.dart';
import 'package:kreso_frontend/features/pos/models/cash_operation.dart';
import 'package:kreso_frontend/features/pos/repository/shift_repository.dart';

/// Открывает модальное окно кассовых операций
Future<bool?> showCashOperationDialog(
  BuildContext context, {
  CashOpType initialType = CashOpType.deposit,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => CashOperationDialog(initialType: initialType),
  );
}

class CashOperationDialog extends StatefulWidget {
  final CashOpType initialType;
  const CashOperationDialog({super.key, this.initialType = CashOpType.deposit});

  @override
  State<CashOperationDialog> createState() => _CashOperationDialogState();
}

class _CashOperationDialogState extends State<CashOperationDialog> {
  late CashOpType _selectedType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();

  String _selectedCategory = 'Разменная монета';
  bool _isLoading = false;
  String? _errorMessage;

  static const List<String> _depCats = ['Разменная монета', 'Довнесение', 'Внесение выручки', 'Прочее'];
  static const List<String> _withCats = ['Инкассация в сейф', 'Хоз. расходы', 'Закупка продуктов', 'Выплата персоналу', 'Прочее'];
  static const List<double> _quickAmounts = [500, 1000, 5000, 10000];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedCategory = _selectedType == CashOpType.deposit ? _depCats.first : _withCats.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _onTypeChanged(CashOpType type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
      _selectedCategory = type == CashOpType.deposit ? _depCats.first : _withCats.first;
      _errorMessage = null;
    });
  }

  void _addQuickAmount(double value) {
    final current = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final next = current + value;
    _amountController.text = next % 1 == 0 ? next.toInt().toString() : next.toStringAsFixed(2);
    _amountController.selection = TextSelection.fromPosition(TextPosition(offset: _amountController.text.length));
  }

  Future<void> _handleSubmit(double currentCash) async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) {
      setState(() => _errorMessage = 'Введите корректную сумму больше нуля');
      return;
    }
    if (_selectedType == CashOpType.withdrawal && amount > currentCash) {
      setState(() => _errorMessage = 'Недостаточно средств в кассе (остаток: ${currentCash.toCurrency(context)})');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ShiftRepository(apiClient.dio);
      final res = await repo.createCashOperation(
        type: _selectedType.apiValue,
        amount: amount,
        category: _selectedCategory,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );

      if (mounted) {
        context.read<ShiftBloc>().add(CheckCurrentShift());
        AppToast.showSuccess(context, res['message'] ?? 'Операция успешно проведена');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shiftState = context.watch<ShiftBloc>().state;
    double currentCash = 0.0;
    if (shiftState is ShiftOpen) {
      final shift = shiftState.shiftDetails;
      currentCash = (shift['current_cash_expected'] ?? shift['opening_cash'] as num?)?.toDouble() ?? 0.0;
    }
    final categories = _selectedType == CashOpType.deposit ? _depCats : _withCats;

    return AppDialog(
      title: 'Кассовая операция',
      icon: _selectedType == CashOpType.deposit ? PhosphorIconsBold.arrowDownLeft : PhosphorIconsBold.arrowUpRight,
      width: 480,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSegmentedControl<CashOpType>(
              selectedValue: _selectedType,
              onValueChanged: _onTypeChanged,
              size: AppSegmentedSize.lg,
              items: const [
                AppSegmentedItem(value: CashOpType.deposit, label: 'Внесение', icon: PhosphorIconsRegular.arrowDownLeft),
                AppSegmentedItem(value: CashOpType.withdrawal, label: 'Расход / Инкассация', icon: PhosphorIconsRegular.arrowUpRight),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppRadii.inputRadius,
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(PhosphorIconsRegular.vault, size: 16, color: AppColors.brandPrimary),
                    const SizedBox(width: 8),
                    Text('В кассе сейчас:', style: AppTextStyles.bodyMedium),
                  ],),
                  Text(currentCash.toCurrency(context), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800, color: AppColors.brandPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _amountController,
              focusNode: _amountFocus,
              labelText: 'Сумма операции',
              hintText: '0.00',
              prefixIcon: Icon(PhosphorIconsRegular.money, size: 18, color: AppColors.brandPrimary),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickAmounts.map((q) => InkWell(
                onTap: () => _addQuickAmount(q),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Text('+${q.toInt()}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                ),
              ),).toList(),
            ),
            const SizedBox(height: 12),
            Text('Категория', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: categories.map((cat) {
                final isSel = _selectedCategory == cat;
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = cat),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.brandPrimary.withValues(alpha: 0.15) : (isDark ? AppColors.darkCard : AppColors.lightCard),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isSel ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder), width: isSel ? 1.5 : 1),
                    ),
                    child: Text(cat, style: AppTextStyles.caption.copyWith(color: isSel ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText), fontWeight: isSel ? FontWeight.w700 : FontWeight.w500)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _commentController,
              labelText: 'Комментарий / Основание (опционально)',
              hintText: 'Например: Закупка бумажных стаканчиков',
              prefixIcon: Icon(PhosphorIconsRegular.note, size: 18, color: AppColors.darkSubtext),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.danger.withValues(alpha: 0.3))),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppGhostButton(label: 'Отмена', onPressed: _isLoading ? null : () => Navigator.of(context).pop(false)),
        AppPrimaryButton(
          label: _selectedType == CashOpType.deposit ? 'Внести в кассу' : 'Списать / Инкассировать',
          icon: _selectedType == CashOpType.deposit ? PhosphorIconsBold.arrowDownLeft : PhosphorIconsBold.arrowUpRight,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : () => _handleSubmit(currentCash),
        ),
      ],
    );
  }
}
