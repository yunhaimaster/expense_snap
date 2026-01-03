import 'package:flutter/material.dart';

import '../../../../data/models/expense.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/loading_overlay.dart';
import '../../../widgets/common/skeleton.dart';
import 'expense_card.dart';

/// 支出列表組件
///
/// 支援分頁載入和滑動刪除
class ExpenseList extends StatelessWidget {
  const ExpenseList({
    super.key,
    required this.expenses,
    required this.isLoading,
    required this.hasMore,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onExpenseTap,
    required this.onExpenseDelete,
  });

  final List<Expense> expenses;
  final bool isLoading;
  final bool hasMore;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final void Function(Expense) onExpenseTap;
  final void Function(Expense) onExpenseDelete;

  @override
  Widget build(BuildContext context) {
    // 初次載入中 - 使用 shimmer 骨架屏
    if (isLoading && expenses.isEmpty) {
      return const ExpenseListSkeleton(itemCount: 5);
    }

    // 空列表
    if (expenses.isEmpty) {
      return EmptyStates.noExpenses();
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // 滾動到底部時載入更多
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200 &&
              hasMore &&
              !isLoading) {
            onLoadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: expenses.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // 載入更多指示器
            if (index >= expenses.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: LoadingIndicator()),
              );
            }

            final expense = expenses[index];
            return ExpenseCard(
              expense: expense,
              onTap: () => onExpenseTap(expense),
              onDismissed: () => onExpenseDelete(expense),
            );
          },
        ),
      ),
    );
  }
}
