import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/validation_rules.dart';
import '../../../l10n/app_localizations.dart';

/// 金額輸入組件
///
/// 使用數字鍵盤，最多 2 位小數
class AmountInput extends StatelessWidget {
  const AmountInput({
    super.key,
    required this.controller,
    required this.label,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? prefix;
  final String? suffix;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        _AmountInputFormatter(),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        suffixText: suffix,
        prefixIcon: const Icon(Icons.attach_money),
      ),
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      textAlign: TextAlign.end,
      onChanged: onChanged,
      validator: validator ?? (value) => _defaultValidator(value, l10n),
      enabled: enabled,
      autofocus: autofocus,
    );
  }

  String? _defaultValidator(String? value, S l10n) {
    if (value == null || value.isEmpty) {
      return l10n.validation_amountRequired;
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return l10n.addExpense_invalidAmount;
    }

    if (amount < ValidationRules.minAmount) {
      return l10n.validation_amountTooSmall(ValidationRules.minAmount);
    }

    if (amount > ValidationRules.maxAmount) {
      return l10n.validation_amountTooLarge(ValidationRules.maxAmount);
    }

    return null;
  }
}

/// 金額格式化器
///
/// 確保輸入的金額格式正確
class _AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // 允許空值
    if (text.isEmpty) {
      return newValue;
    }

    // 不允許以多個零開頭（但允許 "0." 開頭）
    if (text.startsWith('00')) {
      return oldValue;
    }

    // 將單獨的 "." 轉換為 "0."
    if (text == '.') {
      return const TextEditingValue(
        text: '0.',
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    // 驗證數字格式
    final amount = double.tryParse(text);
    if (amount == null && !text.endsWith('.')) {
      return oldValue;
    }

    // 限制整數部分長度（最大 7 位：9,999,999.99）
    final parts = text.split('.');
    if (parts[0].length > 7) {
      return oldValue;
    }

    return newValue;
  }
}

/// 匯率輸入組件
class ExchangeRateInput extends StatelessWidget {
  const ExchangeRateInput({
    super.key,
    required this.controller,
    required this.fromCurrency,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String fromCurrency;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}')),
      ],
      decoration: InputDecoration(
        labelText: l10n.validation_exchangeRateLabel,
        helperText: l10n.validation_exchangeRateHint(fromCurrency),
        prefixIcon: const Icon(Icons.currency_exchange),
      ),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.validation_exchangeRateRequired;
        }
        final rate = double.tryParse(value);
        if (rate == null || rate <= 0) {
          return l10n.validation_exchangeRateInvalid;
        }
        return null;
      },
      enabled: enabled,
    );
  }
}
