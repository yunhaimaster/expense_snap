import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/expense.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';

/// 匯出預覽卡片 — 統計摘要
class ExportPreview extends StatelessWidget {
  const ExportPreview({
    super.key,
    required this.isLoading,
    required this.expenses,
    required this.summary,
    required this.selectedYear,
    required this.selectedMonth,
  });

  final bool isLoading;
  final List<Expense> expenses;
  final MonthSummary? summary;
  final int selectedYear;
  final int selectedMonth;

  @override
  Widget build(BuildContext context) {
    // 載入中 - 使用 shimmer 骨架屏
    if (isLoading) {
      return const ExportPreviewSkeleton();
    }

    if (expenses.isEmpty) {
      final l10n = S.of(context);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: EmptyState(
            illustrationAsset: 'assets/illustrations/empty_expenses.svg',
            title: l10n.export_noData,
            subtitle: l10n.export_noDataMessage(selectedYear, selectedMonth),
            animate: false,
          ),
        ),
      );
    }

    final receiptCount = expenses.where((e) => e.hasReceipt).length;
    final l10n = S.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 圖示
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.description,
                size: 40,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 24),

            // 月份
            Text(
              l10n.export_yearMonth(selectedYear, selectedMonth),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // 統計資料
            _StatRow(
              icon: Icons.receipt_long,
              label: l10n.export_expenseCount,
              value: l10n.export_countUnit(
                summary?.totalCount ?? expenses.length,
              ),
            ),

            const SizedBox(height: 8),

            _StatRow(
              icon: Icons.attach_money,
              label: l10n.export_totalHkd,
              value: summary?.formattedTotalAmount ?? 'HKD 0.00',
              valueColor: AppColors.primary,
            ),

            const SizedBox(height: 8),

            _StatRow(
              icon: Icons.photo,
              label: l10n.export_receiptCount,
              value: l10n.export_imageUnit(receiptCount),
            ),

            const SizedBox(height: 24),

            // 提示文字
            Text(
              l10n.export_hint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 統計列
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
