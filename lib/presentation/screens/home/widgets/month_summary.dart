import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../../../data/models/expense.dart';
import '../../../widgets/common/animated_count.dart';

/// 月份摘要組件
///
/// 顯示當月總支出和筆數，支援切換動畫
class MonthSummaryCard extends StatefulWidget {
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
  State<MonthSummaryCard> createState() => _MonthSummaryCardState();
}

class _MonthSummaryCardState extends State<MonthSummaryCard> {
  // 追蹤滑動方向
  _SlideDirection _slideDirection = _SlideDirection.none;

  void _handlePreviousMonth() {
    setState(() => _slideDirection = _SlideDirection.right);
    widget.onPreviousMonth();
  }

  void _handleNextMonth() {
    setState(() => _slideDirection = _SlideDirection.left);
    widget.onNextMonth();
  }

  @override
  Widget build(BuildContext context) {
    // 減少動畫模式
    final reduceMotion = AnimationUtils.shouldReduceMotion(context);

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
                  onPressed: _handlePreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: '上個月',
                ),
                // 月份標題使用 AnimatedSwitcher（支援減少動畫模式）
                AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : AnimationUtils.standard,
                  switchInCurve: AnimationUtils.emphasized,
                  switchOutCurve: AnimationUtils.standardOut,
                  transitionBuilder: (child, animation) {
                    // 減少動畫模式時直接顯示
                    if (reduceMotion) {
                      return child;
                    }

                    // 根據滑動方向決定動畫
                    final offset = switch (_slideDirection) {
                      _SlideDirection.left => Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ),
                      _SlideDirection.right => Tween<Offset>(
                          begin: const Offset(-1, 0),
                          end: Offset.zero,
                        ),
                      _SlideDirection.none => Tween<Offset>(
                          begin: Offset.zero,
                          end: Offset.zero,
                        ),
                    };

                    return SlideTransition(
                      position: offset.animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    widget.summary.formattedMonth,
                    key: ValueKey(widget.summary.formattedMonth),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: widget.canGoNext ? _handleNextMonth : null,
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
                // 總金額（使用動畫）
                _AnimatedStatItem(
                  label: '總支出',
                  amount: widget.summary.totalHkdAmountCents,
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                ),

                // 分隔線
                Container(
                  height: 40,
                  width: 1,
                  color: AppColors.divider,
                ),

                // 筆數（使用動畫）
                _AnimatedCountStatItem(
                  label: '筆數',
                  count: widget.summary.totalCount,
                  suffix: ' 筆',
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

/// 滑動方向
enum _SlideDirection { left, right, none }

/// 動畫金額統計項目
class _AnimatedStatItem extends StatelessWidget {
  const _AnimatedStatItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final int amount;
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
        AnimatedAmount(
          amount: amount,
          currencySymbol: 'HK\$',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

/// 動畫數量統計項目
class _AnimatedCountStatItem extends StatelessWidget {
  const _AnimatedCountStatItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    this.suffix = '',
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final String suffix;

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
        AnimatedIntCount(
          count: count,
          suffix: suffix,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}
