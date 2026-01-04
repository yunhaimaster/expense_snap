import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_snap/presentation/providers/expense_provider.dart';
import 'package:expense_snap/domain/repositories/expense_repository.dart';
import 'package:expense_snap/services/image_service.dart';
import 'package:expense_snap/data/models/expense.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/core/constants/currency_constants.dart';

@GenerateMocks([IExpenseRepository, ImageService])
import 'expense_provider_test.mocks.dart';

void main() {
  // 測試用資料 - 放在 setUpAll 之前定義
  final now = DateTime.now();
  final testExpense = Expense(
    id: 1,
    date: now,
    originalAmountCents: 10000,
    originalCurrency: 'HKD',
    exchangeRate: CurrencyConstants.ratePrecision,
    exchangeRateSource: ExchangeRateSource.auto,
    hkdAmountCents: 10000,
    description: '測試支出',
    createdAt: now,
    updatedAt: now,
  );

  final testSummary = MonthSummary(
    year: now.year,
    month: now.month,
    totalCount: 1,
    totalHkdAmountCents: 10000,
  );

  // 註冊 dummy values（Mockito 需要）
  setUpAll(() {
    provideDummy<Result<List<Expense>>>(Result.success(<Expense>[]));
    provideDummy<Result<MonthSummary>>(Result.success(testSummary));
    provideDummy<Result<Expense>>(Result.success(testExpense));
    provideDummy<Result<void>>(Result.success(null));
    provideDummy<Result<String>>(Result.success(''));
  });

  late MockIExpenseRepository mockRepository;
  late MockImageService mockImageService;
  late ExpenseProvider provider;

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

    provider = ExpenseProvider(
      repository: mockRepository,
      imageService: mockImageService,
    );
  });

  group('ExpenseProvider 初始化', () {
    test('應初始化為當前月份', () {
      expect(provider.currentYear, now.year);
      expect(provider.currentMonth, now.month);
    });

    test('初始狀態應為空列表', () {
      expect(provider.expenses, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('isCurrentMonth 在當前月份應為 true', () {
      expect(provider.isCurrentMonth, true);
    });

    test('currentMonthDisplay 應格式化正確', () {
      expect(provider.currentMonthDisplay, '${now.year} 年 ${now.month} 月');
    });
  });

  group('ExpenseProvider.loadMonth', () {
    test('成功載入月份資料', () async {
      await provider.loadMonth(refresh: true);

      expect(provider.expenses, hasLength(1));
      expect(provider.expenses.first.id, 1);
      expect(provider.summary.totalCount, 1);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('載入失敗應設定錯誤狀態', () async {
      when(mockRepository.getExpensesByMonth(
        year: anyNamed('year'),
        month: anyNamed('month'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => Result.failure(
            const DatabaseException('查詢失敗'),
          ));

      await provider.loadMonth(refresh: true);

      expect(provider.error, isA<DatabaseException>());
    });

    test('重複調用 loadMonth 時應忽略（防止併發）', () async {
      // 模擬慢速回應
      when(mockRepository.getExpensesByMonth(
        year: anyNamed('year'),
        month: anyNamed('month'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Result.success([testExpense]);
      });

      // 同時調用兩次
      final future1 = provider.loadMonth(refresh: true);
      final future2 = provider.loadMonth(refresh: true);

      await Future.wait([future1, future2]);

      // 應只調用一次
      verify(mockRepository.getExpensesByMonth(
        year: anyNamed('year'),
        month: anyNamed('month'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).called(1);
    });
  });

  group('ExpenseProvider.previousMonth', () {
    test('從 3 月切換到 2 月', () async {
      // 先設置到 3 月
      provider.goToMonth(2025, 3);
      await Future.delayed(Duration.zero); // 等待 async 操作

      // 切換到上個月
      provider.previousMonth();

      expect(provider.currentMonth, 2);
      expect(provider.currentYear, 2025);
    });

    test('從 1 月切換到上一年 12 月', () async {
      provider.goToMonth(2025, 1);
      await Future.delayed(Duration.zero);

      provider.previousMonth();

      expect(provider.currentMonth, 12);
      expect(provider.currentYear, 2024);
    });
  });

  group('ExpenseProvider.nextMonth', () {
    test('從 3 月切換到 4 月', () async {
      // 先設置到過去的月份
      provider.goToMonth(2024, 3);
      await Future.delayed(Duration.zero);

      provider.nextMonth();

      expect(provider.currentMonth, 4);
      expect(provider.currentYear, 2024);
    });

    test('從 12 月切換到下一年 1 月', () async {
      provider.goToMonth(2024, 12);
      await Future.delayed(Duration.zero);

      provider.nextMonth();

      expect(provider.currentMonth, 1);
      expect(provider.currentYear, 2025);
    });

    test('不能超過當前月份', () async {
      // 已經在當前月份
      final originalMonth = provider.currentMonth;
      final originalYear = provider.currentYear;

      provider.nextMonth();

      // 應該保持不變
      expect(provider.currentMonth, originalMonth);
      expect(provider.currentYear, originalYear);
    });
  });

  group('ExpenseProvider.addExpense', () {
    test('成功新增支出', () async {
      when(mockRepository.addExpense(
        expense: anyNamed('expense'),
        imagePath: anyNamed('imagePath'),
      )).thenAnswer((_) async => Result.success(testExpense));

      final result = await provider.addExpense(
        date: now,
        originalAmountCents: 10000,
        originalCurrency: 'HKD',
        exchangeRate: CurrencyConstants.ratePrecision,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 10000,
        description: '測試',
      );

      expect(result.isSuccess, true);
    });

    test('新增失敗應返回錯誤', () async {
      when(mockRepository.addExpense(
        expense: anyNamed('expense'),
        imagePath: anyNamed('imagePath'),
      )).thenAnswer((_) async => Result.failure(
            const DatabaseException('寫入失敗'),
          ));

      final result = await provider.addExpense(
        date: now,
        originalAmountCents: 10000,
        originalCurrency: 'HKD',
        exchangeRate: CurrencyConstants.ratePrecision,
        exchangeRateSource: ExchangeRateSource.auto,
        hkdAmountCents: 10000,
        description: '測試',
      );

      expect(result.isFailure, true);
    });
  });

  group('ExpenseProvider.softDeleteExpense', () {
    test('成功刪除應從列表移除', () async {
      // 先載入資料
      await provider.loadMonth(refresh: true);
      expect(provider.expenses, hasLength(1));

      when(mockRepository.softDeleteExpense(any))
          .thenAnswer((_) async => Result.success(null));

      await provider.softDeleteExpense(1);

      expect(provider.expenses, isEmpty);
    });
  });

  group('ExpenseProvider.pickImage', () {
    test('從相機拍照', () async {
      when(mockImageService.pickFromCamera())
          .thenAnswer((_) async => Result.success('/path/to/image.jpg'));

      final result = await provider.pickImageFromCamera();

      expect(result.isSuccess, true);
    });

    test('從相簿選擇', () async {
      when(mockImageService.pickFromGallery())
          .thenAnswer((_) async => Result.success('/path/to/image.jpg'));

      final result = await provider.pickImageFromGallery();

      expect(result.isSuccess, true);
    });
  });

  group('ExpenseProvider.clearError', () {
    test('應清除錯誤狀態', () async {
      // 先觸發錯誤
      when(mockRepository.getExpensesByMonth(
        year: anyNamed('year'),
        month: anyNamed('month'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => Result.failure(
            const DatabaseException('錯誤'),
          ));

      await provider.loadMonth(refresh: true);
      expect(provider.error, isNotNull);

      provider.clearError();

      expect(provider.error, isNull);
    });
  });
}
