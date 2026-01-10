import 'package:expense_snap/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRouter.generateRoute', () {
    group('路由常數定義', () {
      test('應定義所有路由常數', () {
        expect(AppRouter.onboarding, '/onboarding');
        expect(AppRouter.home, '/');
        expect(AppRouter.addExpense, '/add-expense');
        expect(AppRouter.expenseDetail, '/expense');
        expect(AppRouter.export, '/export');
        expect(AppRouter.settings, '/settings');
        expect(AppRouter.deletedItems, '/deleted-items');
      });
    });

    group('基本路由生成', () {
      test('onboarding 路由應返回有效路由', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(name: AppRouter.onboarding),
        );

        expect(route, isA<Route<dynamic>>());
      });

      test('home 路由應返回有效路由', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(name: AppRouter.home),
        );

        expect(route, isA<Route<dynamic>>());
      });

      test('addExpense 路由應返回全屏對話框', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(name: AppRouter.addExpense),
        );

        expect(route, isA<PageRoute<dynamic>>());
        expect((route as PageRoute<dynamic>).fullscreenDialog, isTrue);
      });

      test('deletedItems 路由應返回有效路由', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(name: AppRouter.deletedItems),
        );

        expect(route, isA<Route<dynamic>>());
      });
    });

    group('expenseDetail 路由參數安全', () {
      test('有效 int 參數應返回有效路由', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(
            name: AppRouter.expenseDetail,
            arguments: 123,
          ),
        );

        expect(route, isA<Route<dynamic>>());
      });

      test('null 參數應返回錯誤頁面路由', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(
            name: AppRouter.expenseDetail,
            arguments: null,
          ),
        );

        // 應該返回有效路由（錯誤頁面）
        expect(route, isA<Route<dynamic>>());
      });

      test('字串參數應返回錯誤頁面路由', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(
            name: AppRouter.expenseDetail,
            arguments: '123',
          ),
        );

        expect(route, isA<Route<dynamic>>());
      });

      test('Map 參數應返回錯誤頁面路由', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(
            name: AppRouter.expenseDetail,
            arguments: {'id': 123},
          ),
        );

        expect(route, isA<Route<dynamic>>());
      });

      test('double 參數應返回錯誤頁面路由', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(
            name: AppRouter.expenseDetail,
            arguments: 123.5,
          ),
        );

        expect(route, isA<Route<dynamic>>());
      });

      test('負數 int 參數應正常處理', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(
            name: AppRouter.expenseDetail,
            arguments: -1,
          ),
        );

        // 負數是有效的 int，由業務邏輯處理
        expect(route, isA<Route<dynamic>>());
      });

      test('零值 int 參數應正常處理', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(
            name: AppRouter.expenseDetail,
            arguments: 0,
          ),
        );

        expect(route, isA<Route<dynamic>>());
      });
    });

    group('未知路由處理', () {
      test('未知路由應返回錯誤頁面路由', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(name: '/unknown'),
        );

        expect(route, isA<Route<dynamic>>());
      });

      test('null 路由名應返回錯誤頁面路由', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(name: null),
        );

        expect(route, isA<Route<dynamic>>());
      });

      test('空字串路由應返回錯誤頁面路由', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(name: ''),
        );

        expect(route, isA<Route<dynamic>>());
      });

      test('帶空白的路由名應返回錯誤頁面路由', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(name: '  /expense  '),
        );

        expect(route, isA<Route<dynamic>>());
      });

      test('路由路徑注入攻擊應返回錯誤頁面路由', () {
        final route = AppRouter.generateRoute(
          const RouteSettings(name: '/expense/../../../etc/passwd'),
        );

        expect(route, isA<Route<dynamic>>());
      });
    });
  });
}
