import 'package:flutter/material.dart';

import '../../../core/constants/expense_category.dart';
import '../../../l10n/app_localizations.dart';

/// 分類選擇器
///
/// 水平滾動的 FilterChip 列表，支援單選和取消選擇
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  /// 當前選中的分類（null 表示未選擇）
  final ExpenseCategory? value;

  /// 選擇變更回調（傳入 null 表示取消選擇）
  final ValueChanged<ExpenseCategory?> onChanged;

  /// 是否啟用
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標籤
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.category_label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        // 分類選擇器
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ExpenseCategory.values.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CategoryChip(
                  category: category,
                  isSelected: category == value,
                  enabled: enabled,
                  onTap: () {
                    if (category == value) {
                      // 點擊已選中的分類 → 取消選擇
                      onChanged(null);
                    } else {
                      onChanged(category);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// 單一分類 Chip
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final ExpenseCategory category;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final categoryName = category.getLocalizedName(l10n);
    final backgroundColor = category.getColor(context);
    final textColor = category.getTextColor(context);

    return Semantics(
      label: categoryName,
      selected: isSelected,
      button: true,
      enabled: enabled,
      child: FilterChip(
        label: Text(categoryName),
        selected: isSelected,
        onSelected: enabled ? (_) => onTap() : null,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        selectedColor: backgroundColor,
        labelStyle: TextStyle(
          color: isSelected ? textColor : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        checkmarkColor: textColor,
        side: isSelected
            ? BorderSide.none
            : BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              ),
      ),
    );
  }
}
