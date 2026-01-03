import 'package:flutter/material.dart';

import '../../../../data/models/expense.dart';
import '../../../widgets/common/animated_list_item.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/loading_overlay.dart';
import '../../../widgets/common/skeleton.dart';
import 'expense_card.dart';

/// 支出列表組件
///
/// 支援分頁載入、滑動刪除和進場動畫
class ExpenseList extends StatefulWidget {
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
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  // 追蹤已動畫的項目，避免重複動畫
  final Set<int> _animatedItems = {};

  // 上次列表長度，用於判斷是否有新項目
  int _previousLength = 0;

  // 最大追蹤項目數（防止記憶體無限增長）
  static const int _maxAnimatedItemsCount = 100;

  @override
  void didUpdateWidget(ExpenseList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 載入完成後重置動畫狀態
    if (oldWidget.isLoading && !widget.isLoading && widget.expenses.isEmpty) {
      _animatedItems.clear();
      _previousLength = 0;
    }

    // 清理過時的追蹤項目，保持記憶體穩定
    _cleanupAnimatedItems();
  }

  /// 清理過時的追蹤項目
  void _cleanupAnimatedItems() {
    if (_animatedItems.length > _maxAnimatedItemsCount) {
      // 保留當前列表中存在的項目
      final currentIds = widget.expenses
          .map((e) => e.id ?? e.hashCode)
          .toSet();
      _animatedItems.removeWhere((id) => !currentIds.contains(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 初次載入中 - 使用 shimmer 骨架屏
    if (widget.isLoading && widget.expenses.isEmpty) {
      return const ExpenseListSkeleton(itemCount: 5);
    }

    // 空列表
    if (widget.expenses.isEmpty) {
      return EmptyStates.noExpenses();
    }

    return RefreshIndicator(
      onRefresh: () async {
        // 刷新時重置動畫狀態
        _animatedItems.clear();
        _previousLength = 0;
        await widget.onRefresh();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // 滾動到底部時載入更多
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200 &&
              widget.hasMore &&
              !widget.isLoading) {
            widget.onLoadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: widget.expenses.length + (widget.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // 載入更多指示器
            if (index >= widget.expenses.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: LoadingIndicator()),
              );
            }

            final expense = widget.expenses[index];
            // 防禦性處理：ID 為空時使用 hashCode 作為備用
            final expenseId = expense.id ?? expense.hashCode;

            // 判斷是否需要動畫：首次載入或新增項目
            final isNewItem = index == 0 &&
                widget.expenses.length > _previousLength &&
                _previousLength > 0;
            final shouldAnimate = !_animatedItems.contains(expenseId);

            // 記錄已動畫項目
            if (shouldAnimate) {
              _animatedItems.add(expenseId);
            }

            // 更新長度記錄
            if (index == widget.expenses.length - 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _previousLength = widget.expenses.length;
              });
            }

            final card = ExpenseCard(
              expense: expense,
              onTap: () => widget.onExpenseTap(expense),
              onDismissed: () => widget.onExpenseDelete(expense),
            );

            // 新增項目從左側滑入
            if (isNewItem) {
              return AnimatedListItem(
                key: ValueKey('anim_$expenseId'),
                index: 0,
                slideFrom: SlideDirection.left,
                child: card,
              );
            }

            // 首次載入使用 stagger 動畫
            if (shouldAnimate) {
              return AnimatedListItem(
                key: ValueKey('anim_$expenseId'),
                index: index,
                slideFrom: SlideDirection.bottom,
                child: card,
              );
            }

            // 已動畫過的項目直接顯示
            return card;
          },
        ),
      ),
    );
  }
}
