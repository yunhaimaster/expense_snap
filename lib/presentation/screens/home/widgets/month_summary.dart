import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/expense.dart';

/// 月份摘要組件
///
/// 顯示當月總支出和筆數
class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({
    super.key,
    required this.summary,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.canGoNext,
  });

  final MonthSummary summary;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 月份導航
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: '上個月',
                ),
                Text(
                  summary.formattedMonth,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: canGoNext ? onNextMonth : null,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: '下個月',
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // 統計資訊
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 總金額
                _StatItem(
                  label: '總支出',
                  value: summary.formattedTotalAmount,
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                ),

                // 分隔線
                Container(
                  height: 40,
                  width: 1,
                  color: AppColors.divider,
                ),

                // 筆數
                _StatItem(
                  label: '筆數',
                  value: '${summary.totalCount} 筆',
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 統計項目
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}
