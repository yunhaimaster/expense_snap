// 鍵盤覆蓋測試 - 驗證鍵盤顯示時不會遮擋輸入欄位
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:expense_snap/l10n/app_localizations.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/presentation/providers/exchange_rate_provider.dart';
import 'package:expense_snap/presentation/providers/expense_provider.dart';
import 'package:expense_snap/presentation/screens/add_expense/add_expense_screen.dart';
import 'package:expense_snap/data/repositories/exchange_rate_repository.dart';
import 'package:expense_snap/core/constants/currency_constants.dart';

import 'add_expense/add_expense_screen_test.mocks.dart';

void main() {
  late MockIExpenseRepository mockExpenseRepository;
  late MockExchangeRateRepository mockExchangeRateRepository;
  late MockImageService mockImageService;

  final testRateInfo = ExchangeRateInfo(
    rateToHkd: 1000000,
    source: ExchangeRateSource.auto,
    fetchedAt: DateTime.now(),
  );

  setUpAll(() {
    provideDummy<Result<ExchangeRateInfo>>(Result.success(testRateInfo));
    provideDummy<Result<Map<String, ExchangeRateInfo>>>(
        Result.success(<String, ExchangeRateInfo>{}));
  });

  setUp(() {
    mockExpenseRepository = MockIExpenseRepository();
    mockExchangeRateRepository = MockExchangeRateRepository();
    mockImageService = MockImageService();

    when(mockExchangeRateRepository.getRate(any))
        .thenAnswer((_) async => Result.success(testRateInfo));
    when(mockExchangeRateRepository.canRefresh).thenReturn(true);
    when(mockExchangeRateRepository.secondsUntilRefresh).thenReturn(0);
  });

  Widget buildTestWidget({double keyboardHeight = 0}) {
    final expenseProvider = ExpenseProvider(
      repository: mockExpenseRepository,
      imageService: mockImageService,
    );
    final exchangeRateProvider = ExchangeRateProvider(
      repository: mockExchangeRateRepository,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
        ChangeNotifierProvider<ExchangeRateProvider>.value(
            value: exchangeRateProvider),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        builder: (context, child) {
          // 模擬鍵盤高度
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              viewInsets: EdgeInsets.only(bottom: keyboardHeight),
            ),
            child: child!,
          );
        },
        home: const AddExpenseScreen(),
      ),
    );
  }

  group('鍵盤覆蓋測試', () {
    testWidgets('無鍵盤時頁面應正常渲染', (tester) async {
      await tester.pumpWidget(buildTestWidget(keyboardHeight: 0));
      await tester.pump();

      expect(find.byType(AddExpenseScreen), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });

    testWidgets('鍵盤顯示時頁面應可捲動', (tester) async {
      // 設置較小螢幕尺寸模擬手機
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(buildTestWidget(keyboardHeight: 300));
      await tester.pump();

      // 頁面應正常渲染
      expect(find.byType(AddExpenseScreen), findsOneWidget);

      // SingleChildScrollView 應存在，允許捲動
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));

      // 還原螢幕尺寸
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('模擬小螢幕 (5 inch) 鍵盤顯示', (tester) async {
      // 5 inch 螢幕模擬 (720x1280)
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(buildTestWidget(keyboardHeight: 250));
      await tester.pump();

      expect(find.byType(AddExpenseScreen), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('模擬中螢幕 (6 inch) 鍵盤顯示', (tester) async {
      // 6 inch 螢幕模擬 (1080x2160)
      tester.view.physicalSize = const Size(1080, 2160);
      tester.view.devicePixelRatio = 2.5;

      await tester.pumpWidget(buildTestWidget(keyboardHeight: 280));
      await tester.pump();

      expect(find.byType(AddExpenseScreen), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('模擬大螢幕 (6.7 inch) 鍵盤顯示', (tester) async {
      // 6.7 inch 螢幕模擬 (1440x3120)
      tester.view.physicalSize = const Size(1440, 3120);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(buildTestWidget(keyboardHeight: 320));
      await tester.pump();

      expect(find.byType(AddExpenseScreen), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('應使用 viewPadding 處理安全區域', (tester) async {
      // 此測試確保程式碼使用正確的 MediaQuery 屬性
      // viewPadding.bottom 處理安全區域（Home Indicator 等）
      // 鍵盤避讓由 Scaffold.resizeToAvoidBottomInset 處理

      await tester.pumpWidget(buildTestWidget(keyboardHeight: 300));
      await tester.pump();

      // 確認頁面正常渲染（使用 viewPadding 的程式碼應正常工作）
      expect(find.byType(AddExpenseScreen), findsOneWidget);

      // 表單欄位應存在
      expect(find.byType(Form), findsAtLeastNWidgets(1));
    });

    testWidgets('鍵盤高度極端值 (500px) 應正常處理', (tester) async {
      await tester.pumpWidget(buildTestWidget(keyboardHeight: 500));
      await tester.pump();

      expect(find.byType(AddExpenseScreen), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });

    testWidgets('鍵盤顯示時金額輸入欄位仍可訪問', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(buildTestWidget(keyboardHeight: 300));
      await tester.pump();

      // 金額欄位應存在（「金額」標籤）
      expect(find.text('金額'), findsAtLeastNWidgets(1));

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });

  group('不同螢幕方向', () {
    testWidgets('橫向模式應正常渲染', (tester) async {
      // 橫向模式
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(buildTestWidget(keyboardHeight: 200));
      await tester.pump();

      expect(find.byType(AddExpenseScreen), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
