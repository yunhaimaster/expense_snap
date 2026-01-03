import 'package:flutter/material.dart';

import '../../../core/constants/currency_constants.dart';
import '../../../core/theme/app_colors.dart';

/// 幣種選擇下拉組件
class CurrencyDropdown extends StatelessWidget {
  const CurrencyDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        labelText: '幣種',
        prefixIcon: Icon(Icons.monetization_on_outlined),
      ),
      items: CurrencyConstants.supportedCurrencies.map((currency) {
        final color = AppColors.currencyColors[currency] ?? AppColors.primary;
        final name = CurrencyConstants.currencyNames[currency] ?? currency;

        return DropdownMenuItem<String>(
          value: currency,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  currency.substring(0, 1),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$currency - $name'),
            ],
          ),
        );
      }).toList(),
      onChanged: enabled ? (v) => onChanged(v!) : null,
    );
  }
}

/// 幣種快速選擇按鈕組
class CurrencyButtonGroup extends StatelessWidget {
  const CurrencyButtonGroup({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: CurrencyConstants.supportedCurrencies.map((currency) {
        final isSelected = currency == value;
        final color = AppColors.currencyColors[currency] ?? AppColors.primary;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _CurrencyButton(
              currency: currency,
              isSelected: isSelected,
              color: color,
              onTap: enabled ? () => onChanged(currency) : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CurrencyButton extends StatelessWidget {
  const _CurrencyButton({
    required this.currency,
    required this.isSelected,
    required this.color,
    this.onTap,
  });

  final String currency;
  final bool isSelected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currency,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyConstants.currencyNames[currency] ?? '',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
