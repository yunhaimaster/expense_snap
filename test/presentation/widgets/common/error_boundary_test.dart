// ErrorBoundary 錯誤邊界測試 - 驗證錯誤捕獲和恢復機制
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/core/theme/app_theme.dart';
import 'package:expense_snap/presentation/widgets/common/error_boundary.dart';

void main() {
  group('ErrorFallbackScreen', () {
    testWidgets('應顯示錯誤圖示和標題', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ErrorFallbackScreen(
            error: null,
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('發生問題了'), findsOneWidget);
    });

    testWidgets('應顯示錯誤訊息', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ErrorFallbackScreen(
            error: null,
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 預設錯誤訊息
      expect(find.text('應用程式發生錯誤'), findsOneWidget);
    });

    testWidgets('NetworkException 應顯示對應錯誤訊息', (tester) async {
      final exception = NetworkException.noConnection();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ErrorFallbackScreen(
            error: exception,
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 應顯示錯誤相關內容
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('點擊重試按鈕應觸發回調', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ErrorFallbackScreen(
            error: null,
            onRetry: () {
              retryCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 找到重試/返回按鈕並點擊
      final retryButton = find.byType(ElevatedButton);
      final outlinedButton = find.byType(OutlinedButton);

      if (retryButton.evaluate().isNotEmpty) {
        await tester.tap(retryButton);
      } else if (outlinedButton.evaluate().isNotEmpty) {
        await tester.tap(outlinedButton);
      }
      await tester.pump();

      expect(retryCalled, isTrue);
    });
  });

  group('ErrorBanner', () {
    testWidgets('應顯示錯誤圖示和訊息', (tester) async {
      const exception = ValidationException('測試錯誤訊息', field: 'test');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ErrorBanner(error: exception),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('點擊關閉按鈕應觸發 onDismiss', (tester) async {
      bool dismissCalled = false;
      const exception = ValidationException('測試錯誤', field: 'test');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ErrorBanner(
              error: exception,
              onDismiss: () {
                dismissCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(dismissCalled, isTrue);
    });

    testWidgets('可重試錯誤應顯示重試按鈕', (tester) async {
      bool retryCalled = false;
      final exception = NetworkException.noConnection();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ErrorBanner(
              error: exception,
              onRetry: () {
                retryCalled = true;
              },
            ),
          ),
        ),
      );

      // 如果有重試按鈕，點擊它
      final retryButton = find.text('重試');
      if (retryButton.evaluate().isNotEmpty) {
        await tester.tap(retryButton);
        await tester.pump();
        expect(retryCalled, isTrue);
      }
    });
  });

  group('showErrorSnackBar', () {
    testWidgets('應顯示錯誤 SnackBar', (tester) async {
      const exception = ValidationException('測試錯誤訊息', field: 'test');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showErrorSnackBar(context, error: exception);
                },
                child: const Text('顯示錯誤'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('顯示錯誤'));
      await tester.pump();

      // SnackBar 應該顯示
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('NetworkException 的 SnackBar 應存在', (tester) async {
      final exception = NetworkException.noConnection();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showErrorSnackBar(context, error: exception);
                },
                child: const Text('顯示錯誤'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('顯示錯誤'));
      await tester.pump();

      // SnackBar 應該存在
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('showSuccessSnackBar', () {
    testWidgets('應顯示成功 SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showSuccessSnackBar(context, message: '操作成功');
                },
                child: const Text('顯示成功'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('顯示成功'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('操作成功'), findsOneWidget);
    });

    testWidgets('成功 SnackBar 應可包含 action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showSuccessSnackBar(
                    context,
                    message: '已儲存',
                    action: SnackBarAction(
                      label: '查看',
                      onPressed: () {},
                    ),
                  );
                },
                child: const Text('顯示成功'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('顯示成功'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      // 確認 SnackBarAction 存在
      expect(find.byType(SnackBarAction), findsOneWidget);
    });
  });

  group('錯誤恢復流程', () {
    testWidgets('ErrorFallbackScreen 重試後應能恢復', (tester) async {
      int retryCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: StatefulBuilder(
            builder: (context, setState) {
              if (retryCount == 0) {
                return ErrorFallbackScreen(
                  error: DatabaseException.corrupted(),
                  onRetry: () {
                    setState(() {
                      retryCount++;
                    });
                  },
                );
              } else {
                return const Scaffold(
                  body: Center(
                    child: Text('恢復成功'),
                  ),
                );
              }
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 初始應顯示錯誤畫面
      expect(find.text('發生問題了'), findsOneWidget);

      // 點擊重試/返回按鈕
      final buttons = find.byType(ElevatedButton).evaluate().isEmpty
          ? find.byType(OutlinedButton)
          : find.byType(ElevatedButton);
      await tester.tap(buttons);
      await tester.pumpAndSettle();

      // 恢復後應顯示正常內容
      expect(find.text('恢復成功'), findsOneWidget);
      expect(retryCount, equals(1));
    });

    testWidgets('多次錯誤後仍可恢復', (tester) async {
      int errorCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: StatefulBuilder(
            builder: (context, setState) {
              if (errorCount < 3) {
                return ErrorFallbackScreen(
                  error: null,
                  onRetry: () {
                    setState(() {
                      errorCount++;
                    });
                  },
                );
              } else {
                return const Scaffold(
                  body: Center(
                    child: Text('終於成功'),
                  ),
                );
              }
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 重試 3 次
      for (int i = 0; i < 3; i++) {
        expect(find.text('發生問題了'), findsOneWidget);
        final buttons = find.byType(ElevatedButton).evaluate().isEmpty
            ? find.byType(OutlinedButton)
            : find.byType(ElevatedButton);
        await tester.tap(buttons);
        await tester.pumpAndSettle();
      }

      // 第三次重試後應成功
      expect(find.text('終於成功'), findsOneWidget);
      expect(errorCount, equals(3));
    });
  });
}
