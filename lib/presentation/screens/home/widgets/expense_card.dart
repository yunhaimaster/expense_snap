import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/currency_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/expense.dart';

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

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
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

                    // 日期和匯率來源
                    Row(
                      children: [
                        Text(
                          Formatters.formatDate(expense.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(width: 8),
                        _buildRateSourceBadge(context),
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
                          color: AppColors.primary,
                        ),
                  ),

                  // 原始金額（如果非港幣）
                  if (expense.originalCurrency != 'HKD')
                    Text(
                      expense.formattedOriginalAmount,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                ],
              ),

              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );

    // 滑動刪除
    if (onDismissed != null) {
      card = Dismissible(
        key: ValueKey(expense.id),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
          ),
        ),
        confirmDismiss: (_) async {
          return await _showDeleteConfirmation(context);
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
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.receipt_outlined,
          color: AppColors.textHint,
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
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.divider,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textHint,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Image.file(
          File(expense.thumbnailPath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.divider,
            child: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.textHint,
            ),
          ),
        ),
      ),
    );
  }

  /// 建立匯率來源標籤
  Widget _buildRateSourceBadge(BuildContext context) {
    final (icon, color, label) = switch (expense.exchangeRateSource) {
      ExchangeRateSource.auto => (Icons.check_circle, AppColors.rateAuto, '即時'),
      ExchangeRateSource.offline => (Icons.offline_bolt, AppColors.rateOffline, '離線'),
      ExchangeRateSource.defaultRate => (Icons.warning, AppColors.rateDefault, '預設'),
      ExchangeRateSource.manual => (Icons.edit, AppColors.rateManual, '手動'),
    };

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
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    // 觸覺回饋 - 滑動到位
    AnimationUtils.mediumImpact();

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('確認刪除'),
            content: const Text('確定要刪除這筆支出嗎？\n刪除後可在「已刪除項目」中還原。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  // 觸覺回饋 - 確認刪除
                  AnimationUtils.mediumImpact();
                  Navigator.of(context).pop(true);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: const Text('刪除'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
