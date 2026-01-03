import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/expense.dart';
import '../../../domain/repositories/expense_repository.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_overlay.dart';

/// 已刪除項目畫面
///
/// 顯示軟刪除的支出，可還原或永久刪除
class DeletedItemsScreen extends StatefulWidget {
  const DeletedItemsScreen({super.key});

  @override
  State<DeletedItemsScreen> createState() => _DeletedItemsScreenState();
}

class _DeletedItemsScreenState extends State<DeletedItemsScreen> {
  List<Expense> _deletedExpenses = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadDeletedExpenses();
  }

  Future<void> _loadDeletedExpenses() async {
    setState(() => _isLoading = true);

    final repository = context.read<IExpenseRepository>();
    final result = await repository.getDeletedExpenses();

    if (!mounted) return;

    result.fold(
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('載入失敗: ${error.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (expenses) {
        setState(() => _deletedExpenses = expenses);
      },
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isProcessing,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('已刪除項目'),
          actions: [
            if (_deletedExpenses.isNotEmpty)
              TextButton(
                onPressed: _confirmClearAll,
                child: const Text(
                  '清空',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_deletedExpenses.isEmpty) {
      return EmptyStates.noDeletedItems();
    }

    return RefreshIndicator(
      onRefresh: _loadDeletedExpenses,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _deletedExpenses.length,
        itemBuilder: (context, index) {
          final expense = _deletedExpenses[index];
          return _DeletedExpenseCard(
            expense: expense,
            onRestore: () => _restoreExpense(expense),
            onDelete: () => _confirmPermanentDelete(expense),
          );
        },
      ),
    );
  }

  Future<void> _restoreExpense(Expense expense) async {
    setState(() => _isProcessing = true);

    final repository = context.read<IExpenseRepository>();
    final result = await repository.restoreExpense(expense.id!);

    if (!mounted) return;

    result.fold(
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('還原失敗: ${error.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (_) {
        setState(() {
          _deletedExpenses.removeWhere((e) => e.id == expense.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已還原')),
        );
      },
    );

    setState(() => _isProcessing = false);
  }

  Future<void> _confirmPermanentDelete(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('永久刪除'),
        content: const Text('此操作無法復原，確定要永久刪除嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('永久刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    final repository = context.read<IExpenseRepository>();
    final result = await repository.permanentlyDeleteExpense(expense.id!);

    if (!mounted) return;

    result.fold(
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刪除失敗: ${error.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (_) {
        setState(() {
          _deletedExpenses.removeWhere((e) => e.id == expense.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已永久刪除')),
        );
      },
    );

    setState(() => _isProcessing = false);
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有'),
        content: Text('確定要永久刪除全部 ${_deletedExpenses.length} 筆記錄嗎？\n此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('全部刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    final repository = context.read<IExpenseRepository>();
    int deletedCount = 0;

    for (final expense in List<Expense>.from(_deletedExpenses)) {
      final result = await repository.permanentlyDeleteExpense(expense.id!);
      if (result.isSuccess) {
        deletedCount++;
        if (mounted) {
          setState(() {
            _deletedExpenses.removeWhere((e) => e.id == expense.id);
          });
        }
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已刪除 $deletedCount 筆記錄')),
    );

    setState(() => _isProcessing = false);
  }
}

/// 已刪除支出卡片
class _DeletedExpenseCard extends StatelessWidget {
  const _DeletedExpenseCard({
    required this.expense,
    required this.onRestore,
    required this.onDelete,
  });

  final Expense expense;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final daysRemaining = expense.daysUntilPermanentDelete ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 縮圖
                _buildThumbnail(),

                const SizedBox(width: 12),

                // 內容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expense.formattedOriginalAmount,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // 刪除資訊和操作按鈕
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: daysRemaining <= 7 ? AppColors.error : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    daysRemaining > 0
                        ? '還有 $daysRemaining 天自動刪除'
                        : '即將自動刪除',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: daysRemaining <= 7
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('還原'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                  ),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('刪除'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
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
}
