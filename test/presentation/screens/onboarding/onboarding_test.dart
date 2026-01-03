import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/presentation/screens/onboarding/onboarding_screen.dart';

void main() {
  group('OnboardingScreen', () {
    // 設定測試用的螢幕大小（避免 overflow）
    const testScreenSize = Size(400, 800);

    testWidgets('renders 3-step carousel', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // 應有 PageView
      expect(find.byType(PageView), findsOneWidget);

      // 應有頁面指示器（3 個圓點）
      // 活躍頁面指示器應該是第一個
      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });

    testWidgets('displays first page content correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // 第一頁標題
      expect(find.text('拍照記錄支出'), findsOneWidget);

      // 第一頁描述
      expect(find.textContaining('隨手拍攝收據'), findsOneWidget);

      // 下一步按鈕
      expect(find.text('下一步'), findsOneWidget);

      // 跳過按鈕
      expect(find.text('跳過'), findsOneWidget);
    });

    testWidgets('navigates to second page on next button tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // 點擊下一步
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      // 第二頁標題
      expect(find.text('多幣種自動轉換'), findsOneWidget);
    });

    testWidgets('navigates through all pages correctly', (tester) async {
      // 設定較大螢幕避免 overflow
      tester.view.physicalSize = testScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // 使用按鈕導航（更可靠）來測試頁面內容變化
      // 第一頁內容已經在其他測試驗證
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      // 應該在第二頁
      expect(find.text('多幣種自動轉換'), findsOneWidget);

      // 點擊下一步到第三頁
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      // 應該在第三頁
      expect(find.text('一鍵匯出報銷單'), findsOneWidget);

      // 最後一頁應顯示「開始使用」按鈕
      expect(find.text('開始使用'), findsOneWidget);
    });

    testWidgets('shows name input on last page', (tester) async {
      // 設定較大螢幕避免 overflow
      tester.view.physicalSize = testScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // 用按鈕導航到最後一頁（更可靠）
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      // 應有名稱輸入欄位
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('您的名字（選填）'), findsOneWidget);
    });

    testWidgets('validates name length', (tester) async {
      // 設定較大螢幕避免 overflow
      tester.view.physicalSize = testScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // 用按鈕導航到最後一頁（更可靠）
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      // 輸入超長名字
      final textField = find.byType(TextFormField);
      await tester.enterText(textField, 'a' * 51);
      await tester.pump();

      // 點擊開始使用觸發驗證
      await tester.tap(find.text('開始使用'));
      await tester.pump();

      // 應顯示錯誤訊息
      expect(find.text('名字不能超過 50 個字'), findsOneWidget);
    });
  });
}
