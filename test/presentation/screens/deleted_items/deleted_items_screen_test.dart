import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:expense_snap/l10n/app_localizations.dart';
import 'package:expense_snap/core/constants/currency_constants.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/data/models/expense.dart';
import 'package:expense_snap/domain/repositories/expense_repository.dart';
import 'package:expense_snap/presentation/screens/deleted_items/deleted_items_screen.dart';
import 'package:expense_snap/presentation/widgets/common/skeleton.dart';

@GenerateMocks([IExpenseRepository])
import 'deleted_items_screen_test.mocks.dart';

void main() {
  late MockIExpenseRepository mockRepository;

  // 測試用 Expense 工廠
  Expense createTestExpense({
    required int id,
    String description = '測試支出',
    int amountCents = 10000,
    String currency = 'HKD',
    DateTime? deletedAt,
  }) {
    final now = DateTime.now();
    return Expense(
      id: id,
      date: now,
      originalAmountCents: amountCents,
      originalCurrency: currency,
      exchangeRate: 1000000,
      exchangeRateSource: ExchangeRateSource.auto,
      convertedAmountCents: amountCents,
      targetCurrency: CurrencyConstants.defaultPrimaryCurrency,
      description: description,
      isDeleted: true,
      deletedAt: deletedAt ?? now.subtract(const Duration(days: 5)),
      createdAt: now,
      updatedAt: now,
    );
  }

  setUpAll(() {
    // 註冊 dummy values
    provideDummy<Result<List<Expense>>>(Result.success(<Expense>[]));
    provideDummy<Result<void>>(Result.success(null));
  });

  setUp(() {
    mockRepository = MockIExpenseRepository();
  });

  // 螢幕大小
  const testScreenSize = Size(400, 800);

  Widget buildTestWidget(
    WidgetTester tester, {
    List<Expense> deletedExpenses = const [],
  }) {
    tester.view.physicalSize = testScreenSize;
    tester.view.devicePixelRatio = 1.0;

    // 設定 getDeletedExpenses 回傳值
    when(
      mockRepository.getDeletedExpenses(),
    ).thenAnswer((_) async => Result.success(deletedExpenses));

    return MultiProvider(
      providers: [
        Provider<IExpenseRepository>.value(value: mockRepository),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: DeletedItemsScreen(),
      ),
    );
  }

  group('DeletedItemsScreen 空列表', () {
    testWidgets('應顯示 AppBar 標題', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      // 「已刪除項目」標題
      expect(find.text('已刪除項目'), findsOneWidget);
    });

    testWidgets('空列表應顯示空狀態畫面', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      // 空狀態提示文字
      expect(find.text('沒有已刪除的項目'), findsOneWidget);
    });

    testWidgets('空列表時不應顯示「清空」按鈕', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('清空'), findsNothing);
    });
  });

  group('DeletedItemsScreen 有項目', () {
    late List<Expense> testExpenses;

    setUp(() {
      testExpenses = [
        createTestExpense(id: 1, description: '早餐', amountCents: 5000),
        createTestExpense(id: 2, description: '午餐', amountCents: 8000),
      ];
    });

    testWidgets('應顯示已刪除的支出項目', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(
        buildTestWidget(tester, deletedExpenses: testExpenses),
      );
      await tester.pumpAndSettle();

      // 應顯示描述文字
      expect(find.text('早餐'), findsOneWidget);
      expect(find.text('午餐'), findsOneWidget);
    });

    testWidgets('應使用 ListView.builder 渲染列表', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(
        buildTestWidget(tester, deletedExpenses: testExpenses),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('有項目時應顯示「清空」按鈕', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(
        buildTestWidget(tester, deletedExpenses: testExpenses),
      );
      await tester.pumpAndSettle();

      expect(find.text('清空'), findsOneWidget);
    });

    testWidgets('每個項目應有還原和刪除按鈕', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(
        buildTestWidget(tester, deletedExpenses: testExpenses),
      );
      await tester.pumpAndSettle();

      // 每個卡片各有一組按鈕
      expect(find.text('還原'), findsNWidgets(2));
      expect(find.text('刪除'), findsNWidgets(2));
    });

    testWidgets('每個項目應顯示還原圖標和刪除圖標', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(
        buildTestWidget(tester, deletedExpenses: testExpenses),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.restore), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_forever), findsNWidgets(2));
    });
  });

  group('DeletedItemsScreen 還原操作', () {
    testWidgets('點擊還原應呼叫 restoreExpense', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      final expense = createTestExpense(id: 1, description: '待還原支出');

      // 設定 stub
      when(
        mockRepository.restoreExpense(1),
      ).thenAnswer((_) async => Result.success(null));

      await tester.pumpWidget(
        buildTestWidget(tester, deletedExpenses: [expense]),
      );
      await tester.pumpAndSettle();

      // 點擊還原按鈕
      await tester.tap(find.text('還原'));
      await tester.pumpAndSettle();

      // 驗證呼叫了 restoreExpense
      verify(mockRepository.restoreExpense(1)).called(1);
    });

    testWidgets('還原成功後應顯示 SnackBar', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      final expense = createTestExpense(id: 1, description: '待還原支出');

      when(
        mockRepository.restoreExpense(1),
      ).thenAnswer((_) async => Result.success(null));

      await tester.pumpWidget(
        buildTestWidget(tester, deletedExpenses: [expense]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('還原'));
      await tester.pumpAndSettle();

      // 應顯示成功 SnackBar
      expect(find.text('已還原'), findsOneWidget);
    });
  });

  group('DeletedItemsScreen 永久刪除操作', () {
    testWidgets('點擊刪除應顯示確認對話框', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      final expense = createTestExpense(id: 1, description: '待刪除支出');

      await tester.pumpWidget(
        buildTestWidget(tester, deletedExpenses: [expense]),
      );
      await tester.pumpAndSettle();

      // 點擊刪除按鈕
      await tester.tap(find.text('刪除'));
      await tester.pumpAndSettle();

      // 應顯示確認對話框
      expect(find.text('永久刪除'), findsAtLeastNWidgets(1));
      expect(find.text('取消'), findsOneWidget);
    });

    testWidgets('確認刪除後應呼叫 permanentlyDeleteExpense', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      final expense = createTestExpense(id: 1, description: '待刪除支出');

      when(
        mockRepository.permanentlyDeleteExpense(1),
      ).thenAnswer((_) async => Result.success(null));

      await tester.pumpWidget(
        buildTestWidget(tester, deletedExpenses: [expense]),
      );
      await tester.pumpAndSettle();

      // 點擊刪除按鈕
      await tester.tap(find.text('刪除'));
      await tester.pumpAndSettle();

      // 點擊確認對話框中的「永久刪除」按鈕
      // 對話框中有標題和按鈕兩個「永久刪除」，點按鈕那個
      final deleteButtons = find.text('永久刪除');
      await tester.tap(deleteButtons.last);
      await tester.pumpAndSettle();

      verify(mockRepository.permanentlyDeleteExpense(1)).called(1);
    });

    testWidgets('取消刪除不應呼叫 permanentlyDeleteExpense', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      final expense = createTestExpense(id: 1, description: '待刪除支出');

      await tester.pumpWidget(
        buildTestWidget(tester, deletedExpenses: [expense]),
      );
      await tester.pumpAndSettle();

      // 點擊刪除按鈕
      await tester.tap(find.text('刪除'));
      await tester.pumpAndSettle();

      // 點擊取消
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      verifyNever(mockRepository.permanentlyDeleteExpense(any));
    });
  });

  group('DeletedItemsScreen 載入狀態', () {
    testWidgets('載入中應顯示骨架屏', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      // 使用 Completer 阻止回應，模擬持續載入
      final completer = Completer<Result<List<Expense>>>();
      when(
        mockRepository.getDeletedExpenses(),
      ).thenAnswer((_) => completer.future);

      tester.view.physicalSize = testScreenSize;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<IExpenseRepository>.value(value: mockRepository),
          ],
          child: const MaterialApp(
            locale: Locale('zh'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            home: DeletedItemsScreen(),
          ),
        ),
      );

      // 只 pump 一次（不等完成），此時仍在載入
      await tester.pump();

      // 應顯示骨架屏（載入中）
      expect(find.byType(ExpenseListSkeleton), findsOneWidget);

      // 完成 completer 以清理 pending futures
      completer.complete(Result.success(<Expense>[]));
      await tester.pumpAndSettle();
    });
  });
}
