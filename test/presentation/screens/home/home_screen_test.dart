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
import 'package:expense_snap/presentation/providers/connectivity_provider.dart';
import 'package:expense_snap/presentation/providers/expense_provider.dart';
import 'package:expense_snap/presentation/providers/showcase_provider.dart';
import 'package:expense_snap/presentation/screens/home/home_screen.dart';
import 'package:expense_snap/services/image_service.dart';

@GenerateMocks([IExpenseRepository, ImageService])
import 'home_screen_test.mocks.dart';

void main() {
  late MockIExpenseRepository mockRepository;
  late MockImageService mockImageService;

  // 測試用 Expense 工廠
  Expense createTestExpense({
    required int id,
    String description = '測試支出',
    int amountCents = 10000,
    String currency = 'HKD',
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
      createdAt: now,
      updatedAt: now,
    );
  }

  final testSummary = MonthSummary(
    year: DateTime.now().year,
    month: DateTime.now().month,
    totalConvertedAmountCents: 0,
    totalCount: 0,
  );

  setUpAll(() {
    // 註冊 dummy values
    provideDummy<Result<List<Expense>>>(Result.success(<Expense>[]));
    provideDummy<Result<MonthSummary>>(Result.success(testSummary));
    provideDummy<Result<void>>(Result.success(null));
    provideDummy<Result<String>>(Result.success(''));
  });

  setUp(() {
    mockRepository = MockIExpenseRepository();
    mockImageService = MockImageService();

    // 預設 stub
    when(
      mockRepository.getExpensesByMonth(
        year: anyNamed('year'),
        month: anyNamed('month'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      ),
    ).thenAnswer((_) async => Result.success(<Expense>[]));

    when(
      mockRepository.getMonthSummary(
        year: anyNamed('year'),
        month: anyNamed('month'),
      ),
    ).thenAnswer((_) async => Result.success(testSummary));
  });

  const testScreenSize = Size(500, 800);

  /// 建立測試 Widget
  ///
  /// 注意：HomeScreen 使用 ShowcaseWidget 和 ConnectivityProvider，
  /// 這些會產生持續動畫，因此不能用 pumpAndSettle，改用 pump + Duration
  Widget buildTestWidget(WidgetTester tester) {
    tester.view.physicalSize = testScreenSize;
    tester.view.devicePixelRatio = 1.0;

    final expenseProvider = ExpenseProvider(
      repository: mockRepository,
      imageService: mockImageService,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
        ChangeNotifierProvider<ShowcaseProvider>(
          create: (_) => ShowcaseProvider(),
        ),
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: HomeScreen(),
      ),
    );
  }

  /// 多次 pump 等待非同步操作完成（替代 pumpAndSettle）
  Future<void> pumpMultiple(WidgetTester tester, {int times = 10}) async {
    for (int i = 0; i < times; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('HomeScreen 基本渲染', () {
    testWidgets('應顯示 Scaffold', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });

    testWidgets('應顯示 FAB（新增支出按鈕）', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('應顯示月份摘要區塊', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      // 月份摘要卡片應存在
      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });
  });

  group('HomeScreen 空狀態', () {
    testWidgets('無支出時應顯示空狀態提示', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      // 使用 pump 等待非同步載入完成，避免 pumpAndSettle 超時
      await pumpMultiple(tester);

      expect(find.text('暫無支出記錄'), findsOneWidget);
    });
  });

  group('HomeScreen 有支出', () {
    setUp(() {
      final expenses = [
        createTestExpense(id: 1, description: '早餐', amountCents: 5000),
        createTestExpense(id: 2, description: '交通', amountCents: 3000),
      ];
      final summaryWithData = MonthSummary(
        year: DateTime.now().year,
        month: DateTime.now().month,
        totalConvertedAmountCents: 8000,
        totalCount: 2,
      );

      when(
        mockRepository.getExpensesByMonth(
          year: anyNamed('year'),
          month: anyNamed('month'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        ),
      ).thenAnswer((_) async => Result.success(expenses));

      when(
        mockRepository.getMonthSummary(
          year: anyNamed('year'),
          month: anyNamed('month'),
        ),
      ).thenAnswer((_) async => Result.success(summaryWithData));
    });

    testWidgets('應顯示支出列表項目', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await pumpMultiple(tester);

      expect(find.text('早餐'), findsOneWidget);
      expect(find.text('交通'), findsOneWidget);
    });
  });

  group('HomeScreen FAB', () {
    testWidgets('FAB 應存在且有正確的 tooltip', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      // 驗證 FAB 的 tooltip
      final fabWidget = tester.widget<FloatingActionButton>(fab);
      expect(fabWidget.tooltip, '新增支出');
    });
  });

  group('HomeScreen UI 結構', () {
    testWidgets('應包含 SafeArea', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      expect(find.byType(SafeArea), findsAtLeastNWidgets(1));
    });

    testWidgets('應使用 Column 排列元件', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });
  });
}
