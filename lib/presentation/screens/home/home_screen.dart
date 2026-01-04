import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/expense_provider.dart';
import '../../providers/showcase_provider.dart';
import '../../widgets/common/animated_fab.dart';
import '../../widgets/common/connectivity_banner.dart';
import 'widgets/expense_list.dart';
import 'widgets/month_summary.dart';

/// 首頁畫面
///
/// 顯示月份摘要和支出列表，包含功能發現提示
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Showcase 鍵
  final _fabShowcaseKey = GlobalKey();
  final _swipeShowcaseKey = GlobalKey();

  // 用於存取 ShowCaseWidget 的 context（在 build 時設定）
  BuildContext? _showcaseContext;

  @override
  void initState() {
    super.initState();
    // 首次載入資料
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadMonth(refresh: true);
      _checkAndStartShowcase();
    });
  }

  /// 檢查並開始 Showcase
  Future<void> _checkAndStartShowcase() async {
    final showcaseProvider = context.read<ShowcaseProvider>();
    await showcaseProvider.initialize();

    if (!mounted) return;

    // 如果需要顯示 FAB 提示
    if (showcaseProvider.shouldShowFabShowcase) {
      // 延遲一下讓畫面完全載入
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      // 使用 ShowCaseWidget 內的 context
      final showcaseContext = _showcaseContext;
      if (showcaseContext != null && showcaseContext.mounted) {
        ShowCaseWidget.of(showcaseContext).startShowCase([_fabShowcaseKey]);
      }
    }
  }

  /// 開始滑動刪除提示
  void _startSwipeShowcase() {
    final showcaseProvider = context.read<ShowcaseProvider>();
    if (showcaseProvider.shouldShowSwipeShowcase) {
      // 使用 ShowCaseWidget 內的 context
      final showcaseContext = _showcaseContext;
      if (showcaseContext != null) {
        ShowCaseWidget.of(showcaseContext).startShowCase([_swipeShowcaseKey]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onComplete: (index, key) {
        final showcaseProvider = context.read<ShowcaseProvider>();
        if (key == _fabShowcaseKey) {
          showcaseProvider.completeFabShowcase();
        } else if (key == _swipeShowcaseKey) {
          showcaseProvider.completeSwipeShowcase();
        }
      },
      builder: (showcaseContext) {
        // 儲存 ShowCaseWidget 內的 context 供後續使用
        _showcaseContext = showcaseContext;
        return _buildContent(showcaseContext);
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // 離線狀態橫幅
              const AnimatedConnectivityBanner(),

              // 月份摘要
              MonthSummaryCard(
                summary: provider.summary,
                onPreviousMonth: provider.previousMonth,
                onNextMonth: provider.nextMonth,
                canGoNext: !provider.isCurrentMonth,
              ),

              // 錯誤提示
              if (provider.error != null)
                _buildErrorBanner(context, provider.error!),

              // 支出列表
              Expanded(
                child: ExpenseList(
                  expenses: provider.expenses,
                  isLoading: provider.isLoading,
                  hasMore: provider.hasMore,
                  onRefresh: provider.refresh,
                  onLoadMore: provider.loadMore,
                  swipeShowcaseKey: _swipeShowcaseKey,
                  onFirstExpenseLoaded: _startSwipeShowcase,
                  onExpenseTap: (expense) {
                    Navigator.of(context).pushNamed(
                      AppRouter.expenseDetail,
                      arguments: expense.id,
                    );
                  },
                  onExpenseDelete: (expense) async {
                    final result = await provider.softDeleteExpense(expense.id!);
                    if (!context.mounted) return;

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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('已刪除支出'),
                            action: SnackBarAction(
                              label: '復原',
                              onPressed: () async {
                                await provider.restoreExpense(expense.id!);
                                if (!context.mounted) return;
                                await provider.refresh();
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          // 空列表時顯示脈動提示
          final showPulse = !provider.isLoading && provider.expenses.isEmpty;
          return Showcase(
            key: _fabShowcaseKey,
            title: '新增支出',
            description: '點擊這裡拍照記錄你的支出',
            targetBorderRadius: BorderRadius.circular(28),
            tooltipBackgroundColor: AppColors.primary,
            textColor: Colors.white,
            child: AnimatedFab(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.addExpense);
              },
              tooltip: '新增支出',
              showPulse: showPulse,
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, AppException error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.errorLight,
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<ExpenseProvider>().clearError();
              context.read<ExpenseProvider>().refresh();
            },
            child: const Text('重試'),
          ),
        ],
      ),
    );
  }
}
