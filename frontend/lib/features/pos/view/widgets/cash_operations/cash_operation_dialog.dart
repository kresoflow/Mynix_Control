// ==============================================================================
//  Kreso Flow — POS: Cash Operation Dialog
//  [UI-KIT] [ФИНАНСЫ] Диалог служебных внесений, расходов и инкассации.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/network/api_client.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_event.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_state.dart';
import 'package:kreso_frontend/features/pos/models/cash_operation.dart';
import 'package:kreso_frontend/features/pos/repository/shift_repository.dart';
import 'package:kreso_frontend/features/pos/view/widgets/shift_hub/shift_pin_dialog.dart';
import 'cash_operation_form_fields.dart';

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

  Future<void> _handleUnlockPin() async {
    final ok = await showShiftPinDialog(context);
    if (ok && mounted) {
      context.read<ShiftBloc>().add(const ToggleFinancialsVisibility(unlock: true));
    }
  }

  Future<void> _handleSubmit(double currentCash, bool isFinancialsUnlocked) async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) {
      setState(() => _errorMessage = 'Введите корректную сумму больше нуля');
      return;
    }
    if (_selectedType == CashOpType.withdrawal && amount > currentCash) {
      final hint = isFinancialsUnlocked ? ' (остаток: ${currentCash.toCurrency(context)})' : '';
      setState(() => _errorMessage = 'Недостаточно средств в кассе$hint');
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
        context.read<ShiftBloc>().add(const CheckCurrentShift());
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
    bool isFinancialsUnlocked = false;
    if (shiftState is ShiftOpen) {
      final shift = shiftState.shiftDetails;
      currentCash = (shift['current_cash_expected'] ?? shift['opening_cash'] as num?)?.toDouble() ?? 0.0;
      isFinancialsUnlocked = shiftState.isFinancialsUnlocked;
    }
    final categories = _selectedType == CashOpType.deposit ? _depCats : _withCats;

    return AppDialog(
      title: 'Кассовая операция',
      icon: _selectedType == CashOpType.deposit ? PhosphorIconsBold.arrowDownLeft : PhosphorIconsBold.arrowUpRight,
      width: 480,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            CashOperationTypeSwitcher(
              selectedType: _selectedType,
              onTypeChanged: _onTypeChanged,
            ),
            const SizedBox(height: 8),
            CashOperationCurrentBanner(
              currentCash: currentCash,
              isFinancialsUnlocked: isFinancialsUnlocked,
              onUnlockPin: _handleUnlockPin,
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _amountController,
              focusNode: _amountFocus,
              labelText: 'Сумма операции',
              hintText: '0.00',
              prefixIcon: Icon(PhosphorIconsRegular.money, size: 16, color: AppColors.brandPrimary),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 6),
            CashOperationQuickAmounts(
              quickAmounts: _quickAmounts,
              onAddAmount: _addQuickAmount,
            ),
            const SizedBox(height: 10),
            Text('Категория', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
            const SizedBox(height: 5),
            CashOperationCategoryChips(
              categories: categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _commentController,
              labelText: 'Комментарий (опционально)',
              hintText: 'Например: Закупка бумажных стаканчиков',
              prefixIcon: Icon(PhosphorIconsRegular.note, size: 16, color: AppColors.darkSubtext),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: AppRadii.radiusXs, border: Border.all(color: AppColors.danger.withValues(alpha: 0.3))),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600)),
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
          onPressed: _isLoading ? null : () => _handleSubmit(currentCash, isFinancialsUnlocked),
        ),
      ],
    );
  }
}
