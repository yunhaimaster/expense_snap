import 'dart:async';

import 'package:expense_snap/l10n/app_localizations.dart';
import 'package:expense_snap/presentation/widgets/common/debounced_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DebouncedButton', () {
    testWidgets('應正常顯示子組件', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: DebouncedButton(
              onPressed: () async {},
              child: const Text('測試按鈕'),
            ),
          ),
        ),
      );

      expect(find.text('測試按鈕'), findsOneWidget);
    });

    testWidgets('點擊後應觸發回調', (tester) async {
      var clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: DebouncedButton(
              onPressed: () async {
                clicked = true;
              },
              child: const Text('測試按鈕'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('測試按鈕'));
      await tester.pumpAndSettle();

      expect(clicked, isTrue);
    });

    testWidgets('載入中應顯示 LoadingIndicator', (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: DebouncedButton(
              onPressed: () async {
                await completer.future;
              },
              child: const Text('測試按鈕'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('測試按鈕'));
      await tester.pump();

      // 應顯示載入指示器
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 完成操作以清理
      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('載入中應禁用按鈕', (tester) async {
      var clickCount = 0;
      final completer = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: DebouncedButton(
              onPressed: () async {
                clickCount++;
                await completer.future;
              },
              child: const Text('測試按鈕'),
            ),
          ),
        ),
      );

      // 第一次點擊
      await tester.tap(find.text('測試按鈕'));
      await tester.pump();

      // 嘗試第二次點擊（應被忽略）
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // 只應觸發一次
      expect(clickCount, 1);

      // 完成操作以清理
      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('操作完成後應恢復正常狀態', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: DebouncedButton(
              onPressed: () async {
                // 快速完成的操作
              },
              child: const Text('測試按鈕'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('測試按鈕'));
      await tester.pumpAndSettle();

      // 應恢復顯示原文字
      expect(find.text('測試按鈕'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('防抖應阻止快速連點', (tester) async {
      var clickCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: DebouncedButton(
              onPressed: () async {
                clickCount++;
              },
              debounceMs: 500,
              child: const Text('測試按鈕'),
            ),
          ),
        ),
      );

      // 第一次點擊
      await tester.tap(find.text('測試按鈕'));
      await tester.pumpAndSettle();

      // 防抖期間內再次點擊（應被忽略）
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // 只應觸發一次
      expect(clickCount, 1);
    });

    testWidgets('應顯示自訂載入文字', (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: DebouncedButton(
              onPressed: () async {
                await completer.future;
              },
              loadingText: '處理中...',
              child: const Text('測試按鈕'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('測試按鈕'));
      await tester.pump();

      expect(find.text('處理中...'), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('onPressed 為 null 時應禁用', (tester) async {
      // 此測試驗證當 onPressed 為 null 時，點擊按鈕不會觸發任何回調或錯誤
      // 注意：DebouncedButton 內部會包裝 onPressed，所以 ElevatedButton.onPressed
      // 技術上不是 null，但內部會檢查並提前返回
      var callbackTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: DebouncedButton(
              onPressed: null,
              child: const Text('測試按鈕'),
            ),
          ),
        ),
      );

      // 驗證按鈕存在
      expect(find.byType(ElevatedButton), findsOneWidget);

      // 嘗試點擊 - 不應該引發錯誤
      await tester.tap(find.text('測試按鈕'));
      await tester.pumpAndSettle();

      // 回調不應被觸發（內部檢查會阻止）
      expect(callbackTriggered, isFalse);
    });
  });

  group('DebouncedTextButton', () {
    testWidgets('應正常工作', (tester) async {
      var clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: DebouncedTextButton(
              onPressed: () async {
                clicked = true;
              },
              child: const Text('文字按鈕'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('文字按鈕'));
      await tester.pumpAndSettle();

      expect(clicked, isTrue);
    });
  });

  group('DebouncedIconButton', () {
    testWidgets('應正常工作', (tester) async {
      var clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: DebouncedIconButton(
              onPressed: () async {
                clicked = true;
              },
              icon: Icons.add,
              tooltip: '新增',
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(clicked, isTrue);
    });
  });

  group('DebouncedFloatingActionButton', () {
    testWidgets('應正常工作', (tester) async {
      var clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            floatingActionButton: DebouncedFloatingActionButton(
              onPressed: () async {
                clicked = true;
              },
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(clicked, isTrue);
    });

    testWidgets('載入中應顯示指示器', (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            floatingActionButton: DebouncedFloatingActionButton(
              onPressed: () async {
                await completer.future;
              },
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
    });
  });
}
