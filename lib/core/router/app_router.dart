import 'package:flutter/material.dart';

import '../../presentation/screens/add_expense/add_expense_screen.dart';
import '../../presentation/screens/deleted_items/deleted_items_screen.dart';
import '../../presentation/screens/expense_detail/expense_detail_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/shell/app_shell.dart';

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
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const AppShell(),
          settings: settings,
        );

      case addExpense:
        return MaterialPageRoute(
          builder: (_) => const AddExpenseScreen(),
          settings: settings,
          fullscreenDialog: true,
        );

      case expenseDetail:
        // 安全的類型檢查
        final args = settings.arguments;
        if (args is! int) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('錯誤')),
              body: const Center(
                child: Text('無效的支出 ID'),
              ),
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => ExpenseDetailScreen(expenseId: args),
          settings: settings,
        );

      case deletedItems:
        return MaterialPageRoute(
          builder: (_) => const DeletedItemsScreen(),
          settings: settings,
        );

      // export 和 settings 會在 AppShell 中處理

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
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
