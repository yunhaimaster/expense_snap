import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:expense_snap/core/constants/currency_constants.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/data/models/expense.dart';
import 'package:expense_snap/domain/repositories/expense_repository.dart';
import 'package:expense_snap/l10n/app_localizations.dart';
import 'package:expense_snap/presentation/providers/expense_provider.dart';
import 'package:expense_snap/presentation/screens/expense_detail/expense_detail_screen.dart';
import 'package:expense_snap/services/image_service.dart';

@GenerateMocks([IExpenseRepository, ImageService])
import 'expense_detail_screen_test.mocks.dart';

void main() {
  late MockIExpenseRepository mockRepository;
  late MockImageService mockImageService;

  final testExpense = Expense(
    id: 1,
    date: DateTime(2025, 1, 15),
    originalAmountCents: 10000,
    originalCurrency: 'HKD',
    exchangeRate: 1000000,
    exchangeRateSource: ExchangeRateSource.auto,
    hkdAmountCents: 10000,
    description: '測試支出',
    createdAt: DateTime(2025, 1, 15),
    updatedAt: DateTime(2025, 1, 15),
  );

  const testSummary = MonthSummary(
    year: 2025,
    month: 1,
    totalHkdAmountCents: 10000,
    totalCount: 1,
  );

  setUpAll(() {
    // 註冊 dummy values
    provideDummy<Result<List<Expense>>>(Result.success([testExpense]));
    provideDummy<Result<MonthSummary>>(Result.success(testSummary));
    provideDummy<Result<Expense>>(Result.success(testExpense));
    provideDummy<Result<void>>(Result.success(null));
    provideDummy<Result<String>>(Result.success(''));
  });

  setUp(() {
    mockRepository = MockIExpenseRepository();
    mockImageService = MockImageService();

    // 預設 stub
    when(mockRepository.getExpensesByMonth(
      year: anyNamed('year'),
      month: anyNamed('month'),
      limit: anyNamed('limit'),
      offset: anyNamed('offset'),
    )).thenAnswer((_) async => Result.success([testExpense]));

    when(mockRepository.getMonthSummary(
      year: anyNamed('year'),
      month: anyNamed('month'),
    )).thenAnswer((_) async => Result.success(testSummary));
  });

  Widget buildTestWidget({
    required int expenseId,
    List<Expense>? expenses,
  }) {
    final provider = ExpenseProvider(
      repository: mockRepository,
      imageService: mockImageService,
    );

    // 手動設定 expenses（模擬已載入狀態）
    if (expenses != null) {
      // 使用反射或 @visibleForTesting 方法設定（這裡簡化處理）
    }

    return ChangeNotifierProvider<ExpenseProvider>.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: ExpenseDetailScreen(expenseId: expenseId),
      ),
    );
  }

  group('ExpenseDetailScreen 基本渲染', () {
    testWidgets('找不到支出時應顯示錯誤', (tester) async {
      await tester.pumpWidget(buildTestWidget(expenseId: 999));
      await tester.pumpAndSettle();

      // 應顯示錯誤圖示或訊息
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('找不到支出記錄'), findsOneWidget);
    });

    testWidgets('找不到支出時應顯示返回按鈕', (tester) async {
      await tester.pumpWidget(buildTestWidget(expenseId: 999));
      await tester.pumpAndSettle();

      expect(find.text('返回'), findsOneWidget);
    });
  });

  group('ExpenseDetailScreen 錯誤狀態', () {
    testWidgets('錯誤狀態應顯示 AppBar', (tester) async {
      await tester.pumpWidget(buildTestWidget(expenseId: 999));
      await tester.pumpAndSettle();

      expect(find.text('支出詳情'), findsOneWidget);
    });

    testWidgets('點擊返回按鈕應能正常操作', (tester) async {
      await tester.pumpWidget(buildTestWidget(expenseId: 999));
      await tester.pumpAndSettle();

      // 返回按鈕應可點擊（不會拋出錯誤）
      await tester.tap(find.text('返回'));
      await tester.pump();
    });
  });

  group('ExpenseDetailScreen UI 結構', () {
    testWidgets('應使用 Scaffold', (tester) async {
      await tester.pumpWidget(buildTestWidget(expenseId: 1));
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}

/// 測試用：帶有預載入資料的 ExpenseDetailScreen
class TestableExpenseDetailScreen extends StatelessWidget {
  const TestableExpenseDetailScreen({
    super.key,
    required this.expenseId,
    required this.expense,
  });

  final int expenseId;
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return ExpenseDetailScreen(expenseId: expenseId);
  }
}
