import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// 空狀態組件
///
/// 用於顯示列表為空時的友善提示
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  /// 圖標
  final IconData icon;

  /// 標題
  final String title;

  /// 副標題（可選）
  final String? subtitle;

  /// 操作按鈕文字（可選）
  final String? actionLabel;

  /// 操作按鈕（可選，優先於 actionLabel）
  final Widget? action;

  /// 操作回調（可選）
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 圖標
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // 標題
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),

            // 副標題
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],

            // 操作按鈕
            if (action != null || actionLabel != null) ...[
              const SizedBox(height: 24),
              action ??
                  ElevatedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 預設空狀態工廠
class EmptyStates {
  EmptyStates._();

  /// 無支出記錄
  static EmptyState noExpenses({VoidCallback? onAddExpense}) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: '暫無支出記錄',
      subtitle: '點擊右下角按鈕新增第一筆支出',
      actionLabel: onAddExpense != null ? '新增支出' : null,
      onAction: onAddExpense,
    );
  }

  /// 無已刪除項目
  static EmptyState noDeletedItems() {
    return const EmptyState(
      icon: Icons.delete_outline,
      title: '沒有已刪除的項目',
      subtitle: '刪除的支出會在這裡保留 30 天',
    );
  }

  /// 載入失敗
  static EmptyState error({required String message, VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.error_outline,
      title: '載入失敗',
      subtitle: message,
      actionLabel: onRetry != null ? '重試' : null,
      onAction: onRetry,
    );
  }
}
