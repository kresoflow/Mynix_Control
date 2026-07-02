import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';

class CurrencyFormatter {
  static String format(BuildContext context, num amount) {
    final currency = context.read<SettingsBloc>().state.currency;
    return '${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)} $currency';
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
