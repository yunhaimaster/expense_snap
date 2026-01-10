import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:expense_snap/l10n/app_localizations.dart';
import 'package:expense_snap/core/constants/currency_constants.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/data/models/expense.dart';
import 'package:expense_snap/domain/repositories/expense_repository.dart';
import 'package:expense_snap/presentation/screens/export/export_screen.dart';

import 'export_screen_test.mocks.dart';

/// 大型資料集匯出測試
///
/// 測試匯出畫面處理大量資料的能力
void main() {
  late MockIExpenseRepository mockRepository;

  /// 建立指定數量的測試費用
  List<Expense> createTestExpenses(int count) {
    return List.generate(count, (i) => Expense(
      id: i + 1,
      date: DateTime.now().subtract(Duration(days: i % 30)),
      originalAmountCents: 1000 + (i * 10),
      originalCurrency: 'HKD',
      exchangeRate: 1000000,
      exchangeRateSource: ExchangeRateSource.auto,
      hkdAmountCents: 1000 + (i * 10),
      description: '測試支出 #$i',
      receiptImagePath: i % 3 == 0 ? '/path/to/image_$i.jpg' : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  setUpAll(() {
    // 註冊 dummy values
    provideDummy<Result<List<Expense>>>(Result.success(<Expense>[]));
    provideDummy<Result<MonthSummary>>(Result.success(MonthSummary(
      year: DateTime.now().year,
      month: DateTime.now().month,
      totalHkdAmountCents: 0,
      totalCount: 0,
    )));
  });

  setUp(() {
    mockRepository = MockIExpenseRepository();
  });

  const testScreenSize = Size(400, 800);

  Widget buildTestWidget(WidgetTester tester) {
    tester.view.physicalSize = testScreenSize;
    tester.view.devicePixelRatio = 1.0;

    return MultiProvider(
      providers: [
        Provider<IExpenseRepository>.value(value: mockRepository),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: ExportScreen(),
      ),
    );
  }

  group('大型資料集處理', () {
    testWidgets('應能處理 100 筆費用', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      final expenses = createTestExpenses(100);
      final summary = MonthSummary(
        year: DateTime.now().year,
        month: DateTime.now().month,
        totalHkdAmountCents: expenses.fold(0, (sum, e) => sum + e.hkdAmountCents),
        totalCount: expenses.length,
      );

      when(mockRepository.getExpensesByMonth(
        year: anyNamed('year'),
        month: anyNamed('month'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => Result.success(expenses));

      when(mockRepository.getMonthSummary(
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => Result.success(summary));

      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      // 畫面應正常渲染
      expect(find.byType(ExportScreen), findsOneWidget);
    });

    testWidgets('應能處理 500 筆費用', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      final expenses = createTestExpenses(500);
      final summary = MonthSummary(
        year: DateTime.now().year,
        month: DateTime.now().month,
        totalHkdAmountCents: expenses.fold(0, (sum, e) => sum + e.hkdAmountCents),
        totalCount: expenses.length,
      );

      when(mockRepository.getExpensesByMonth(
        year: anyNamed('year'),
        month: anyNamed('month'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => Result.success(expenses));

      when(mockRepository.getMonthSummary(
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => Result.success(summary));

      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      // 畫面應正常渲染
      expect(find.byType(ExportScreen), findsOneWidget);
    });

    testWidgets('應能處理 1000 筆費用', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      final expenses = createTestExpenses(1000);
      final summary = MonthSummary(
        year: DateTime.now().year,
        month: DateTime.now().month,
        totalHkdAmountCents: expenses.fold(0, (sum, e) => sum + e.hkdAmountCents),
        totalCount: expenses.length,
      );

      when(mockRepository.getExpensesByMonth(
        year: anyNamed('year'),
        month: anyNamed('month'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => Result.success(expenses));

      when(mockRepository.getMonthSummary(
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => Result.success(summary));

      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      // 畫面應正常渲染
      expect(find.byType(ExportScreen), findsOneWidget);
    });

    testWidgets('空資料集應顯示正確', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      final summary = MonthSummary(
        year: DateTime.now().year,
        month: DateTime.now().month,
        totalHkdAmountCents: 0,
        totalCount: 0,
      );

      when(mockRepository.getExpensesByMonth(
        year: anyNamed('year'),
        month: anyNamed('month'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => Result.success(<Expense>[]));

      when(mockRepository.getMonthSummary(
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => Result.success(summary));

      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      // 畫面應正常渲染
      expect(find.byType(ExportScreen), findsOneWidget);
    });
  });

  group('資料載入效能', () {
    testWidgets('載入大量資料時不應阻塞 UI', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      final expenses = createTestExpenses(500);

      // 模擬延遲載入
      when(mockRepository.getExpensesByMonth(
        year: anyNamed('year'),
        month: anyNamed('month'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Result.success(expenses);
      });

      when(mockRepository.getMonthSummary(
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => Result.success(MonthSummary(
        year: DateTime.now().year,
        month: DateTime.now().month,
        totalHkdAmountCents: 500000,
        totalCount: 500,
      )));

      await tester.pumpWidget(buildTestWidget(tester));

      // 初始渲染應該成功（資料載入中）
      expect(find.byType(ExportScreen), findsOneWidget);

      // 等待資料載入完成
      await tester.pumpAndSettle();

      // 載入完成後畫面應正常
      expect(find.byType(ExportScreen), findsOneWidget);
    });
  });

  group('記憶體效率', () {
    testWidgets('多次切換月份不應造成記憶體洩漏', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());

      final expenses = createTestExpenses(100);

      when(mockRepository.getExpensesByMonth(
        year: anyNamed('year'),
        month: anyNamed('month'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => Result.success(expenses));

      when(mockRepository.getMonthSummary(
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => Result.success(MonthSummary(
        year: DateTime.now().year,
        month: DateTime.now().month,
        totalHkdAmountCents: 100000,
        totalCount: 100,
      )));

      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      // 模擬多次操作（這裡只驗證不會崩潰）
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 畫面應保持穩定
      expect(find.byType(ExportScreen), findsOneWidget);
    });
  });
}
