import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/currency_constants.dart';
import '../../../../core/constants/expense_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/expense.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/category_badge.dart';

/// 支出卡片組件
///
/// 顯示單筆支出的摘要資訊
class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.expense,
    required this.onTap,
    this.onDismissed,
  });

  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback? onDismissed;

  /// 建立語意描述（供螢幕閱讀器使用）
  String _buildSemanticLabel(S l10n) {
    final buffer = StringBuffer();
    buffer.write('${l10n.semantic_expenseItem(expense.description)} ');
    if (expense.category != null) {
      final categoryName = expense.category!.getLocalizedName(l10n);
      buffer.write('${l10n.semantic_category_prefix}：$categoryName。');
    }
    buffer.write('${l10n.semantic_amount(expense.formattedHkdAmount)} ');
    if (expense.originalCurrency != 'HKD') {
      buffer.write('${l10n.semantic_originalAmount(expense.formattedOriginalAmount)} ');
    }
    buffer.write('${l10n.semantic_date(Formatters.formatDate(expense.date))} ');
    buffer.write('${l10n.semantic_rateSource(_getRateSourceLabel(l10n))} ');
    if (expense.hasReceipt) {
      buffer.write('${l10n.semantic_hasReceipt}。');
    }
    buffer.write(l10n.semantic_tapForDetails);
    if (onDismissed != null) {
      buffer.write('，${l10n.semantic_swipeToDelete}');
    }
    return buffer.toString();
  }

  /// 取得匯率來源文字標籤
  String _getRateSourceLabel(S l10n) {
    return switch (expense.exchangeRateSource) {
      ExchangeRateSource.auto => l10n.rateSource_auto,
      ExchangeRateSource.offline => l10n.rateSource_offline,
      ExchangeRateSource.defaultRate => l10n.rateSource_default,
      ExchangeRateSource.manual => l10n.rateSource_manual,
    };
  }

  /// 取得簡短匯率來源標籤（用於 badge 顯示）
  String _getRateSourceShortLabel(S l10n) {
    return switch (expense.exchangeRateSource) {
      ExchangeRateSource.auto => l10n.rateSource_auto_short,
      ExchangeRateSource.offline => l10n.rateSource_offline_short,
      ExchangeRateSource.defaultRate => l10n.rateSource_default_short,
      ExchangeRateSource.manual => l10n.rateSource_manual_short,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    // RepaintBoundary 減少列表滾動時的重繪範圍
    Widget card = RepaintBoundary(
      child: Semantics(
      label: _buildSemanticLabel(l10n),
      button: true,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  // 縮圖
                  _buildThumbnail(),

                  const SizedBox(width: 12),

                  // 內容
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 描述
                        Text(
                          expense.description,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // 日期、分類、匯率來源
                        Row(
                          children: [
                            Text(
                              Formatters.formatDate(expense.date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            _buildRateSourceBadge(context, l10n),
                            // 分類標籤
                            if (expense.category != null) ...[
                              const SizedBox(width: 8),
                              CategoryBadge(
                                category: expense.category!,
                                compact: true,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 金額
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 港幣金額
                      Text(
                        expense.formattedHkdAmount,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),

                      // 原始金額（如果非港幣）
                      if (expense.originalCurrency != 'HKD')
                        Text(
                          expense.formattedOriginalAmount,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),

                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).hintColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );

    // 滑動刪除
    if (onDismissed != null) {
      card = Dismissible(
        key: ValueKey(expense.id),
        direction: DismissDirection.endToStart,
        background: Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
        ),
        confirmDismiss: (_) async {
          return await _showDeleteConfirmation(context, l10n);
        },
        onDismissed: (_) => onDismissed!(),
        child: card,
      );
    }

    return card;
  }

  /// 建立縮圖
  Widget _buildThumbnail() {
    // 無收據時不使用 Hero（避免動畫衝突）
    if (!expense.hasReceipt) {
      return Builder(
        builder: (context) => Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.receipt_outlined,
            color: Theme.of(context).hintColor,
          ),
        ),
      );
    }

    // 有收據時使用 Hero 動畫（確保 id 非空）
    final expenseId = expense.id;
    if (expenseId == null) {
      // 防禦性處理：ID 為空時不使用 Hero
      return _buildThumbnailImage();
    }

    return Hero(
      tag: HeroTags.receiptImage(expenseId),
      // 避免動畫過程中裁剪
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            // 動畫過程中平滑變換圓角
            final borderRadius = BorderRadius.circular(
              8.0 * (1 - animation.value),
            );
            return ClipRRect(
              borderRadius: borderRadius,
              child: Image.file(
                File(expense.thumbnailPath!),
                fit: BoxFit.cover,
                errorBuilder: (ctx, error, stack) => Container(
                  color: Theme.of(ctx).dividerColor,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Theme.of(ctx).hintColor,
                  ),
                ),
              ),
            );
          },
        );
      },
      child: _buildThumbnailImage(),
    );
  }

  /// 建立縮圖圖片（不含 Hero）
  Widget _buildThumbnailImage() {
    // RepaintBoundary 隔離圖片渲染，避免影響其他元素
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Builder(
            builder: (context) => Image.file(
              File(expense.thumbnailPath!),
              fit: BoxFit.cover,
              // 快取提示
              cacheWidth: 96,
              cacheHeight: 96,
              errorBuilder: (ctx, error, stack) => Container(
                color: Theme.of(ctx).dividerColor,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Theme.of(ctx).hintColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 建立匯率來源標籤
  Widget _buildRateSourceBadge(BuildContext context, S l10n) {
    // 根據主題選擇顏色
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, color) = switch (expense.exchangeRateSource) {
      ExchangeRateSource.auto => (
          Icons.check_circle,
          isDark ? AppColors.dark.rateAuto : AppColors.rateAuto,
        ),
      ExchangeRateSource.offline => (
          Icons.offline_bolt,
          isDark ? AppColors.dark.rateOffline : AppColors.rateOffline,
        ),
      ExchangeRateSource.defaultRate => (
          Icons.warning,
          isDark ? AppColors.dark.rateDefault : AppColors.rateDefault,
        ),
      ExchangeRateSource.manual => (
          Icons.edit,
          isDark ? AppColors.dark.rateManual : AppColors.rateManual,
        ),
    };
    final label = _getRateSourceShortLabel(l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 顯示刪除確認對話框
  Future<bool> _showDeleteConfirmation(BuildContext context, S l10n) async {
    // 觸覺回饋 - 滑動到位
    unawaited(AnimationUtils.mediumImpact());

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.expenseDetail_confirmDelete),
            content: Text(l10n.expenseDetail_confirmDeleteMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.common_cancel),
              ),
              TextButton(
                onPressed: () {
                  // 觸覺回饋 - 確認刪除
                  AnimationUtils.mediumImpact();
                  Navigator.of(context).pop(true);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(l10n.common_delete),
              ),
            ],
          ),
        ) ??
        false;
  }
}
