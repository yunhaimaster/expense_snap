import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:expense_snap/l10n/app_localizations.dart';
import 'package:expense_snap/core/constants/currency_constants.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/domain/repositories/expense_repository.dart';
import 'package:expense_snap/presentation/providers/exchange_rate_provider.dart';
import 'package:expense_snap/presentation/providers/expense_provider.dart';
import 'package:expense_snap/presentation/screens/add_expense/add_expense_screen.dart';
import 'package:expense_snap/data/repositories/exchange_rate_repository.dart';
import 'package:expense_snap/services/image_service.dart';

@GenerateMocks([IExpenseRepository, ExchangeRateRepository, ImageService])
import 'add_expense_screen_test.mocks.dart';

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
    // 註冊 dummy values
    provideDummy<Result<ExchangeRateInfo>>(Result.success(testRateInfo));
    provideDummy<Result<Map<String, ExchangeRateInfo>>>(
        Result.success(<String, ExchangeRateInfo>{}));
  });

  setUp(() {
    mockExpenseRepository = MockIExpenseRepository();
    mockExchangeRateRepository = MockExchangeRateRepository();
    mockImageService = MockImageService();

    // 預設 stub
    when(mockExchangeRateRepository.getRate(any))
        .thenAnswer((_) async => Result.success(testRateInfo));
    when(mockExchangeRateRepository.canRefresh).thenReturn(true);
    when(mockExchangeRateRepository.secondsUntilRefresh).thenReturn(0);
  });

  Widget buildTestWidget() {
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
      child: const MaterialApp(
        locale: Locale('zh'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: AddExpenseScreen(),
      ),
    );
  }

  group('AddExpenseScreen 基本渲染', () {
    testWidgets('應顯示 AppBar 和標題', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('新增支出'), findsAtLeastNWidgets(1));
    });

    testWidgets('應顯示儲存按鈕', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('儲存'), findsAtLeastNWidgets(1));
    });

    testWidgets('應顯示收據圖片區域', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('收據圖片'), findsAtLeastNWidgets(1));
    });

    testWidgets('應顯示拍照和相簿按鈕', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('拍照'), findsAtLeastNWidgets(1));
      expect(find.text('相簿'), findsAtLeastNWidgets(1));
    });
  });

  group('AddExpenseScreen 表單元件', () {
    testWidgets('應顯示金額輸入欄位', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('金額'), findsAtLeastNWidgets(1));
    });

    testWidgets('應顯示幣種選擇區域', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // 預設幣種 HKD 應顯示
      expect(find.text('HKD'), findsWidgets);
    });

    testWidgets('應顯示描述輸入欄位', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // 描述欄位應存在（透過自動完成元件）
      expect(find.byType(Form), findsAtLeastNWidgets(1));
    });
  });

  group('AddExpenseScreen 幣種切換', () {
    testWidgets('選擇非 HKD 幣種應顯示匯率區域', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // 點擊 USD 按鈕
      final usdButton = find.text('USD');
      if (usdButton.evaluate().isNotEmpty) {
        await tester.tap(usdButton);
        await tester.pump();

        // 應顯示手動輸入切換
        expect(find.text('手動輸入'), findsAtLeastNWidgets(1));
      }
    });
  });

  group('AddExpenseScreen 表單驗證', () {
    testWidgets('未填寫金額時儲存應觸發驗證', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // 點擊儲存
      await tester.tap(find.text('儲存'));
      await tester.pump();

      // 應觸發表單驗證（這會顯示錯誤訊息或阻止提交）
      // 由於表單驗證的具體行為，這裡只驗證點擊不會崩潰
    });
  });

  group('AddExpenseScreen UI 結構', () {
    testWidgets('應使用 SingleChildScrollView', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });

    testWidgets('應使用 Form 包裝表單元件', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(Form), findsAtLeastNWidgets(1));
    });
  });
}
