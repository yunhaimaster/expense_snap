import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/expense.dart';

/// 智慧提示對話框
class SmartPromptDialogs {
  SmartPromptDialogs._();

  /// 顯示重複支出警告
  ///
  /// 返回 true 表示繼續儲存，false 表示取消
  static Future<bool> showDuplicateWarning(
    BuildContext context, {
    required Expense existingExpense,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 8),
            const Text('可能重複'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('發現相似的支出記錄：'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existingExpense.description,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HKD ${Formatters.formatCurrency(existingExpense.hkdAmountCents / 100)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatDate(existingExpense.date),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('確定要繼續新增嗎？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('繼續新增'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 顯示大金額確認
  ///
  /// 返回 true 表示確認，false 表示取消
  static Future<bool> showLargeAmountConfirmation(
    BuildContext context, {
    required double amount,
    required String currency,
    required double hkdAmount,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.attach_money,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 8),
            const Text('大金額確認'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '您即將記錄一筆大金額支出：',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary),
              ),
              child: Column(
                children: [
                  Text(
                    '$currency ${Formatters.formatCurrency(amount)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                  if (currency != 'HKD') ...[
                    const SizedBox(height: 4),
                    Text(
                      '≈ HKD ${Formatters.formatCurrency(hkdAmount)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('請確認金額是否正確？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('返回修改'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('確認正確'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 顯示月底匯出提醒
  static Future<void> showMonthEndReminder(
    BuildContext context, {
    required int expenseCount,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: AppColors.primary,
            ),
            SizedBox(width: 8),
            Text('月底提醒'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本月即將結束！',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '您本月共有 $expenseCount 筆支出記錄',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text('建議您匯出報銷單，以便月結報銷。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍後'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // 導航到匯出頁面
              Navigator.of(context).pushNamed('/export');
            },
            icon: const Icon(Icons.file_download),
            label: const Text('去匯出'),
          ),
        ],
      ),
    );
  }
}
