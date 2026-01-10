import 'package:flutter/material.dart';

import '../../../core/constants/expense_category.dart';
import '../../../l10n/app_localizations.dart';

/// 分類標籤
///
/// 顯示在支出卡片上的小型彩色標籤
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.category,
    this.compact = false,
  });

  /// 分類
  final ExpenseCategory category;

  /// 是否使用緊湊模式（較小尺寸）
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final categoryName = category.getLocalizedName(l10n);
    final backgroundColor = category.getColor(context);
    final textColor = category.getTextColor(context);

    return Semantics(
      label: '${l10n.semantic_category_prefix}：$categoryName',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(compact ? 4 : 6),
        ),
        child: Text(
          categoryName,
          style: TextStyle(
            color: textColor,
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
