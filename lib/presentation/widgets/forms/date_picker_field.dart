import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

/// 日期選擇欄位（含快捷按鈕）
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = '日期',
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.showQuickButtons = true,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String label;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// 是否顯示「今天」「昨天」快捷按鈕
  final bool showQuickButtons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 快捷按鈕
        if (showQuickButtons) ...[
          _QuickDateButtons(
            selectedDate: value,
            onDateSelected: onChanged,
            enabled: enabled,
          ),
          const SizedBox(height: 8),
        ],

        // 日期選擇器
        InkWell(
          onTap: enabled ? () => _showDatePicker(context) : null,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.calendar_today),
              suffixIcon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.textSecondary,
              ),
            ),
            child: Text(
              Formatters.formatDate(value),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? now,
      locale: const Locale('zh', 'TW'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged(picked);
    }
  }
}

/// 月份選擇欄位
class MonthPickerField extends StatelessWidget {
  const MonthPickerField({
    super.key,
    required this.year,
    required this.month,
    required this.onChanged,
    this.label = '月份',
  });

  final int year;
  final int month;
  final void Function(int year, int month) onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showMonthPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.date_range),
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.textSecondary,
          ),
        ),
        child: Text(
          '$year 年 $month 月',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    final now = DateTime.now();
    int selectedYear = year;
    int selectedMonth = month;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('選擇月份'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 年份選擇
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() => selectedYear--);
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        '$selectedYear 年',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: selectedYear < now.year
                            ? () {
                                setState(() => selectedYear++);
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 月份選擇
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(12, (index) {
                      final m = index + 1;
                      final isDisabled = selectedYear == now.year && m > now.month;
                      final isSelected = m == selectedMonth;

                      return SizedBox(
                        width: 60,
                        child: ElevatedButton(
                          onPressed: isDisabled
                              ? null
                              : () {
                                  setState(() => selectedMonth = m);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? AppColors.primary
                                : AppColors.surface,
                            foregroundColor: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text('$m 月'),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    onChanged(selectedYear, selectedMonth);
                    Navigator.of(context).pop();
                  },
                  child: const Text('確定'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// 日期快捷按鈕
class _QuickDateButtons extends StatelessWidget {
  const _QuickDateButtons({
    required this.selectedDate,
    required this.onDateSelected,
    required this.enabled,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    return Row(
      children: [
        _QuickDateChip(
          label: '今天',
          isSelected: selectedDay == today,
          onTap: enabled ? () => onDateSelected(today) : null,
        ),
        const SizedBox(width: 8),
        _QuickDateChip(
          label: '昨天',
          isSelected: selectedDay == yesterday,
          onTap: enabled ? () => onDateSelected(yesterday) : null,
        ),
      ],
    );
  }
}

/// 日期快捷按鈕 Chip
class _QuickDateChip extends StatelessWidget {
  const _QuickDateChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isSelected ? AppColors.primaryLight : null,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
    );
  }
}
