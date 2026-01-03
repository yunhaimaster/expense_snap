import 'package:flutter/material.dart';

import '../../presentation/screens/add_expense/add_expense_screen.dart';
import '../../presentation/screens/deleted_items/deleted_items_screen.dart';
import '../../presentation/screens/expense_detail/expense_detail_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/shell/app_shell.dart';
import 'page_transitions.dart';

/// App 路由管理
class AppRouter {
  AppRouter._();

  // 路由名稱常數
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String addExpense = '/add-expense';
  static const String expenseDetail = '/expense';
  static const String export = '/export';
  static const String settings = '/settings';
  static const String deletedItems = '/deleted-items';

  /// 生成路由
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        // Onboarding 使用淡入效果
        return FadePageRoute(
          page: const OnboardingScreen(),
          settings: settings,
        );

      case home:
        // 首頁使用標準淡入
        return FadePageRoute(
          page: const AppShell(),
          settings: settings,
        );

      case addExpense:
        // 新增支出從底部滑入（模態對話框風格）
        return BottomSlidePageRoute(
          page: const AddExpenseScreen(),
          settings: settings,
          fullscreenDialog: true,
        );

      case expenseDetail:
        // 安全的類型檢查
        final args = settings.arguments;
        if (args is! int) {
          return SlidePageRoute(
            page: Scaffold(
              appBar: AppBar(title: const Text('錯誤')),
              body: const Center(
                child: Text('無效的支出 ID'),
              ),
            ),
            settings: settings,
          );
        }
        // 詳情頁面從右滑入（支援 Hero 動畫）
        return SlidePageRoute(
          page: ExpenseDetailScreen(expenseId: args),
          settings: settings,
        );

      case deletedItems:
        // 已刪除項目從右滑入
        return SlidePageRoute(
          page: const DeletedItemsScreen(),
          settings: settings,
        );

      // export 和 settings 會在 AppShell 中處理

      default:
        return SlidePageRoute(
          page: Scaffold(
            appBar: AppBar(title: const Text('頁面不存在')),
            body: Center(
              child: Text('找不到路由: ${settings.name}'),
            ),
          ),
          settings: settings,
        );
    }
  }
}
