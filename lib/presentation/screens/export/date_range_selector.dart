import 'package:flutter/material.dart';

import '../../widgets/forms/date_picker_field.dart';

/// 月份選擇器（含匯出中禁用效果）
class DateRangeSelector extends StatelessWidget {
  const DateRangeSelector({
    super.key,
    required this.year,
    required this.month,
    required this.isExporting,
    required this.onChanged,
  });

  final int year;
  final int month;
  final bool isExporting;
  final void Function(int year, int month) onChanged;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isExporting,
      child: Opacity(
        opacity: isExporting ? 0.5 : 1.0,
        child: MonthPickerField(
          year: year,
          month: month,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
