import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/expense.dart';
import '../../../l10n/app_localizations.dart';

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
    // 在顯示對話框前捕獲 l10n，避免 context 問題
    final l10n = S.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 8),
            Text(l10n.dialog_duplicateTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dialog_duplicateMessage),
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
            Text(l10n.dialog_duplicateConfirm),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.dialog_duplicateContinue),
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
    // 在顯示對話框前捕獲 l10n，避免 context 問題
    final l10n = S.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.attach_money,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 8),
            Text(l10n.dialog_largeAmountTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dialog_largeAmountMessage,
              style: Theme.of(dialogContext).textTheme.bodyMedium,
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
                    style: Theme.of(dialogContext)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
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
            Text(l10n.dialog_largeAmountConfirm),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.dialog_largeAmountBack),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.dialog_largeAmountOk),
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
    // 在顯示對話框前捕獲 l10n，避免 context 問題
    final l10n = S.of(context);
    // 捕獲 Navigator 以便在對話框關閉後使用
    final navigator = Navigator.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(l10n.dialog_monthEndTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dialog_monthEndMessage,
              style: Theme.of(dialogContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dialog_monthEndExpenseCount(expenseCount),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(l10n.dialog_monthEndSuggestion),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.dialog_later),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // 導航到匯出頁面
              navigator.pushNamed('/export');
            },
            icon: const Icon(Icons.file_download),
            label: Text(l10n.dialog_goExport),
          ),
        ],
      ),
    );
  }
}
