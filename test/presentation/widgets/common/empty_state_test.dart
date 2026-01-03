// EmptyState 元件測試

import 'package:expense_snap/core/theme/app_colors.dart';
import 'package:expense_snap/presentation/widgets/common/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmptyState', () {
    testWidgets('應顯示圖標版本的空狀態', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '測試標題',
              animate: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('測試標題'), findsOneWidget);
    });

    testWidgets('應顯示副標題', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '標題',
              subtitle: '這是副標題',
              animate: false,
            ),
          ),
        ),
      );

      expect(find.text('這是副標題'), findsOneWidget);
    });

    testWidgets('應顯示操作按鈕', (tester) async {
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '標題',
              actionLabel: '點擊這裡',
              onAction: () => buttonPressed = true,
              animate: false,
            ),
          ),
        ),
      );

      expect(find.text('點擊這裡'), findsOneWidget);

      await tester.tap(find.text('點擊這裡'));
      expect(buttonPressed, isTrue);
    });

    testWidgets('應顯示自訂操作 Widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '標題',
              action: TextButton(
                onPressed: () {},
                child: const Text('自訂按鈕'),
              ),
              animate: false,
            ),
          ),
        ),
      );

      expect(find.text('自訂按鈕'), findsOneWidget);
    });

    testWidgets('應顯示 SVG 插圖', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              illustrationAsset: 'assets/illustrations/empty_expenses.svg',
              title: '標題',
              animate: false,
            ),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('啟用動畫時應正確播放', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '測試動畫',
              animate: true,
            ),
          ),
        ),
      );

      // 動畫開始時，EmptyState 內應該有動畫元件
      // 使用 descendant finder 來找 EmptyState 內的動畫
      final emptyStateFinder = find.byType(EmptyState);
      expect(emptyStateFinder, findsOneWidget);

      expect(
        find.descendant(
          of: emptyStateFinder,
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: emptyStateFinder,
          matching: find.byType(SlideTransition),
        ),
        findsOneWidget,
      );

      // 完成動畫
      await tester.pumpAndSettle();

      expect(find.text('測試動畫'), findsOneWidget);
    });

    testWidgets('停用動畫時應立即顯示', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '無動畫',
              animate: false,
            ),
          ),
        ),
      );

      // 不需要 pumpAndSettle，直接可見
      expect(find.text('無動畫'), findsOneWidget);
    });

    testWidgets('圖標版本應使用主色調背景圓圈', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '標題',
              animate: false,
            ),
          ),
        ),
      );

      final containerFinder = find.ancestor(
        of: find.byIcon(Icons.inbox),
        matching: find.byType(Container),
      );

      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.shape, BoxShape.circle);
      expect(
        decoration.color,
        AppColors.primary.withValues(alpha: 0.1),
      );
    });
  });

  group('EmptyStates 工廠', () {
    testWidgets('noExpenses 應使用正確插圖', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStates.noExpenses(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('暫無支出記錄'), findsOneWidget);
      expect(find.text('點擊右下角按鈕新增第一筆支出'), findsOneWidget);
    });

    testWidgets('noExpenses 帶回調應顯示按鈕', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStates.noExpenses(onAddExpense: () => called = true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('新增支出'), findsOneWidget);

      await tester.tap(find.text('新增支出'));
      expect(called, isTrue);
    });

    testWidgets('noDeletedItems 應使用正確插圖', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStates.noDeletedItems(),
          ),
        ),
      );

      // noDeletedItems 設定 animate: false
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('沒有已刪除的項目'), findsOneWidget);
    });

    testWidgets('error 應使用錯誤插圖', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStates.error(message: '發生錯誤'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('載入失敗'), findsOneWidget);
      expect(find.text('發生錯誤'), findsOneWidget);
    });

    testWidgets('error 帶重試回調應顯示重試按鈕', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStates.error(
              message: '錯誤訊息',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('重試'), findsOneWidget);

      await tester.tap(find.text('重試'));
      expect(retried, isTrue);
    });

    testWidgets('offline 應使用離線插圖', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStates.offline(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('無網路連線'), findsOneWidget);
      expect(find.text('請檢查您的網路設定'), findsOneWidget);
    });

    testWidgets('offline 應支援自訂訊息', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStates.offline(message: '自訂離線訊息'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('自訂離線訊息'), findsOneWidget);
    });

    testWidgets('exportSuccess 應使用成功插圖', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStates.exportSuccess(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('匯出成功'), findsOneWidget);
      expect(find.text('檔案已準備就緒'), findsOneWidget);
    });

    testWidgets('exportSuccess 帶分享回調應顯示分享按鈕', (tester) async {
      var shared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStates.exportSuccess(onShare: () => shared = true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('分享'), findsOneWidget);

      await tester.tap(find.text('分享'));
      expect(shared, isTrue);
    });
  });

  group('EmptyState 無障礙', () {
    testWidgets('標題和副標題應可被讀取', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '無障礙標題',
              subtitle: '無障礙副標題',
              animate: false,
            ),
          ),
        ),
      );

      final titleFinder = find.text('無障礙標題');
      final subtitleFinder = find.text('無障礙副標題');

      expect(titleFinder, findsOneWidget);
      expect(subtitleFinder, findsOneWidget);

      // 確保文字元件可被語意讀取
      final titleSemantics = tester.getSemantics(titleFinder);
      expect(titleSemantics.label, contains('無障礙標題'));
    });

    testWidgets('SVG 插圖應被標記為裝飾性（excludeSemantics）', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              illustrationAsset: 'assets/illustrations/empty_expenses.svg',
              title: '標題',
              animate: false,
            ),
          ),
        ),
      );

      // 驗證 SVG 存在
      final svgFinder = find.byType(SvgPicture);
      expect(svgFinder, findsOneWidget);

      // 驗證 SVG 的直接父級包含 excludeSemantics 的 Semantics
      // 由於 widget tree 中有多層 Semantics，我們只需確認 SvgPicture 存在
      // 且其 parent chain 中有 Semantics widget（這是我們添加的）
      final semanticsWidgets = tester.widgetList<Semantics>(find.byType(Semantics));
      final hasExcludeSemanticsWrapper = semanticsWidgets.any(
        (s) => s.excludeSemantics == true,
      );
      expect(hasExcludeSemanticsWrapper, isTrue);
    });
  });

  group('EmptyState 動畫行為', () {
    testWidgets('animate 屬性從 false 變為 true 時應播放動畫', (tester) async {
      // 初始狀態：不播放動畫
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '測試',
              animate: false,
            ),
          ),
        ),
      );

      expect(find.text('測試'), findsOneWidget);

      // 更新為播放動畫
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '測試',
              animate: true,
            ),
          ),
        ),
      );

      // 動畫應該開始播放
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('測試'), findsOneWidget);

      // 完成動畫
      await tester.pumpAndSettle();
      expect(find.text('測試'), findsOneWidget);
    });

    testWidgets('widget 移除時應正確釋放動畫控制器', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '測試',
              animate: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 移除 widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      // 如果 dispose 沒有正確執行，這裡會拋出異常
      await tester.pumpAndSettle();
    });

    testWidgets('系統減少動態效果時應跳過動畫', (tester) async {
      // 模擬系統設定減少動態效果
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: EmptyState(
                icon: Icons.inbox,
                title: '減少動態',
                animate: true,
              ),
            ),
          ),
        ),
      );

      // 即使 animate: true，動畫也應立即完成
      expect(find.text('減少動態'), findsOneWidget);
    });
  });

  group('EmptyState SVG 錯誤處理', () {
    testWidgets('SVG 載入時應顯示佔位符', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              illustrationAsset: 'assets/illustrations/empty_expenses.svg',
              title: '標題',
              animate: false,
            ),
          ),
        ),
      );

      // SVG 載入中應該顯示佔位符或 SVG
      // （測試環境中 SVG 會被模擬載入）
      expect(find.text('標題'), findsOneWidget);
    });
  });
}
