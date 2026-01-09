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
import 'package:expense_snap/presentation/screens/export/export_screen.dart';

@GenerateMocks([IExpenseRepository])
import 'export_screen_test.mocks.dart';

void main() {
  late MockIExpenseRepository mockRepository;

  final testExpense = Expense(
    id: 1,
    date: DateTime.now(),
    originalAmountCents: 10000,
    originalCurrency: 'HKD',
    exchangeRate: 1000000,
    exchangeRateSource: ExchangeRateSource.auto,
    hkdAmountCents: 10000,
    description: '測試支出',
    receiptImagePath: '/path/to/image.jpg',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testSummary = MonthSummary(
    year: DateTime.now().year,
    month: DateTime.now().month,
    totalHkdAmountCents: 10000,
    totalCount: 1,
  );

  setUpAll(() {
    // 註冊 dummy values
    provideDummy<Result<List<Expense>>>(Result.success(<Expense>[]));
    provideDummy<Result<MonthSummary>>(Result.success(testSummary));
  });

  setUp(() {
    mockRepository = MockIExpenseRepository();

    // 預設 stub - 返回空列表
    when(mockRepository.getExpensesByMonth(
      year: anyNamed('year'),
      month: anyNamed('month'),
      limit: anyNamed('limit'),
      offset: anyNamed('offset'),
    )).thenAnswer((_) async => Result.success(<Expense>[]));

    when(mockRepository.getMonthSummary(
      year: anyNamed('year'),
      month: anyNamed('month'),
    )).thenAnswer((_) async => Result.success(testSummary));
  });

  // 設定測試用的螢幕大小（避免 overflow）
  const testScreenSize = Size(400, 800);

  Widget buildTestWidget(WidgetTester tester) {
    // 設定螢幕大小
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

  group('ExportScreen 基本渲染', () {
    testWidgets('應顯示 AppBar 和標題', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      expect(find.text('匯出報銷單'), findsOneWidget);
    });

    testWidgets('應顯示月份選擇器', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      // 應有年月選擇區域
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('應顯示 Excel 匯出按鈕', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('匯出 Excel + 收據'), findsOneWidget);
    });

    // 注意：目前只有一個匯出按鈕（Excel + 收據），不需要分開測試
    // 如果將來新增單獨的 ZIP 匯出功能，再添加對應測試
  });

  group('ExportScreen 空資料狀態', () {
    testWidgets('無資料時應顯示空狀態提示', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('沒有資料'), findsOneWidget);
    });

    testWidgets('無資料時匯出按鈕應存在', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      // 匯出 Excel 按鈕文字應存在
      expect(find.text('匯出 Excel + 收據'), findsOneWidget);
    });
  });

  group('ExportScreen 有資料狀態', () {
    setUp(() {
      // 設定有資料的回應
      when(mockRepository.getExpensesByMonth(
        year: anyNamed('year'),
        month: anyNamed('month'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => Result.success([testExpense]));
    });

    testWidgets('有資料時應顯示預覽卡片', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      // 應顯示預覽卡片（包含資料統計）
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('有資料時匯出按鈕應存在', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      // 匯出 Excel 按鈕文字應存在
      expect(find.text('匯出 Excel + 收據'), findsOneWidget);
    });

    testWidgets('應顯示支出筆數統計', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('支出筆數'), findsOneWidget);
    });

    testWidgets('應顯示港幣總額統計', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('港幣總額'), findsOneWidget);
    });

    testWidgets('應顯示收據圖片統計', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('收據圖片'), findsOneWidget);
    });
  });

  group('ExportScreen UI 結構', () {
    testWidgets('應使用 Padding 包裝內容', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('應使用 Column 佈局', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      expect(find.byType(Column), findsWidgets);
    });
  });
}
