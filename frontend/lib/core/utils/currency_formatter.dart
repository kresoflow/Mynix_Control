import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';

class CurrencyFormatter {
  static String format(BuildContext context, num amount) {
    final currency = context.read<SettingsBloc>().state.currency;
    final isInt = amount.truncateToDouble() == amount;
    final formatter = NumberFormat(isInt ? '#,##0' : '#,##0.00', 'ru_RU');
    final formatted = formatter.format(amount).replaceAll('\u00A0', ' ');
    return '$formatted $currency';
  }

  static String symbol(BuildContext context) {
    return context.read<SettingsBloc>().state.currency;
  }
}

extension CurrencyExtension on num {
  String toCurrency(BuildContext context) {
    return CurrencyFormatter.format(context, this);
  }
}
