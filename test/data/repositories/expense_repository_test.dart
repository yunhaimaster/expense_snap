import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:expense_snap/core/constants/currency_constants.dart';
import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/data/datasources/local/database_helper.dart';
import 'package:expense_snap/data/models/expense.dart';
import 'package:expense_snap/data/repositories/expense_repository.dart';
import 'package:expense_snap/services/image_service.dart';

@GenerateMocks([DatabaseHelper, ImageService])
import 'expense_repository_test.mocks.dart';

void main() {
  late MockDatabaseHelper mockDatabaseHelper;
  late MockImageService mockImageService;
  late ExpenseRepository repository;

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

  final testExpenseMap = {
    'id': 1,
    'date': '2025-01-15',
    'original_amount': 10000,
    'original_currency': 'HKD',
    'exchange_rate': 1000000,
    'exchange_rate_source': 'auto',
    'hkd_amount': 10000,
    'description': '測試支出',
    'receipt_image_path': null,
    'thumbnail_path': null,
    'is_deleted': 0,
    'deleted_at': null,
    'created_at': '2025-01-15T00:00:00.000',
    'updated_at': '2025-01-15T00:00:00.000',
  };

  const testImagePaths = ProcessedImagePaths(
    fullPath: '/images/test_full.jpg',
    thumbnailPath: '/images/test_thumb.jpg',
  );

  setUpAll(() {
    // 註冊 dummy values
    provideDummy<Result<ProcessedImagePaths>>(Result.success(testImagePaths));
    provideDummy<Result<void>>(Result.success(null));
  });

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    mockImageService = MockImageService();
    repository = ExpenseRepository(
      databaseHelper: mockDatabaseHelper,
      imageService: mockImageService,
    );

    // 預設 stub - deleteImages 總是成功
    when(mockImageService.deleteImages(
      fullPath: anyNamed('fullPath'),
      thumbnailPath: anyNamed('thumbnailPath'),
    )).thenAnswer((_) async => Result.success(null));

    // 預設 stub - processReceiptImage 總是成功
    when(mockImageService.processReceiptImage(
      sourcePath: anyNamed('sourcePath'),
      expenseDate: anyNamed('expenseDate'),
    )).thenAnswer((_) async => Result.success(testImagePaths));

    // 預設 stub - updateExpense 總是成功
    when(mockDatabaseHelper.updateExpense(any, any))
        .thenAnswer((_) async => 1);
  });

  group('ExpenseRepository addExpense', () {
    test('新增支出成功（無圖片）', () async {
      // Arrange
      when(mockDatabaseHelper.insertExpense(any)).thenAnswer((_) async => 1);

      final newExpense = testExpense.copyWith(id: null);

      // Act
      final result = await repository.addExpense(expense: newExpense);

      // Assert
      expect(result.isSuccess, isTrue);
      final saved = result.getOrThrow();
      expect(saved.id, 1);
      verify(mockDatabaseHelper.insertExpense(any)).called(1);
      verifyNever(mockImageService.processReceiptImage(
        sourcePath: anyNamed('sourcePath'),
        expenseDate: anyNamed('expenseDate'),
      ));
    });

    test('新增支出成功（含圖片）', () async {
      // Arrange
      when(mockDatabaseHelper.insertExpense(any)).thenAnswer((_) async => 1);
      when(mockImageService.processReceiptImage(
        sourcePath: anyNamed('sourcePath'),
        expenseDate: anyNamed('expenseDate'),
      )).thenAnswer((_) async => Result.success(testImagePaths));

      final newExpense = testExpense.copyWith(id: null);

      // Act
      final result = await repository.addExpense(
        expense: newExpense,
        imagePath: '/temp/receipt.jpg',
      );

      // Assert
      expect(result.isSuccess, isTrue);
      final saved = result.getOrThrow();
      expect(saved.receiptImagePath, testImagePaths.fullPath);
      expect(saved.thumbnailPath, testImagePaths.thumbnailPath);
      verify(mockImageService.processReceiptImage(
        sourcePath: anyNamed('sourcePath'),
        expenseDate: anyNamed('expenseDate'),
      )).called(1);
    });

    test('圖片處理失敗時應回傳錯誤', () async {
      // Arrange
      when(mockImageService.processReceiptImage(
        sourcePath: anyNamed('sourcePath'),
        expenseDate: anyNamed('expenseDate'),
      )).thenAnswer((_) async =>
          Result.failure(const StorageException('Image processing failed')));

      final newExpense = testExpense.copyWith(id: null);

      // Act
      final result = await repository.addExpense(
        expense: newExpense,
        imagePath: '/temp/receipt.jpg',
      );

      // Assert
      expect(result.isFailure, isTrue);
      verifyNever(mockDatabaseHelper.insertExpense(any));
    });

    test('資料庫插入失敗時應回傳錯誤', () async {
      // Arrange
      when(mockDatabaseHelper.insertExpense(any))
          .thenThrow(Exception('DB error'));

      final newExpense = testExpense.copyWith(id: null);

      // Act
      final result = await repository.addExpense(expense: newExpense);

      // Assert
      expect(result.isFailure, isTrue);
    });
  });

  group('ExpenseRepository updateExpense', () {
    test('更新支出成功', () async {
      // Arrange
      when(mockDatabaseHelper.updateExpense(any, any))
          .thenAnswer((_) async => 1);

      // Act
      final result = await repository.updateExpense(testExpense);

      // Assert
      expect(result.isSuccess, isTrue);
      verify(mockDatabaseHelper.updateExpense(1, any)).called(1);
    });

    test('無 ID 時應回傳驗證錯誤', () async {
      // Arrange - 建立沒有 ID 的 Expense（copyWith 無法將 ID 設為 null）
      final expenseNoId = Expense(
        id: null,
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

      // Act
      final result = await repository.updateExpense(expenseNoId);

      // Assert
      expect(result.isFailure, isTrue);
      final error = (result as Failure).error;
      expect(error, isA<ValidationException>());
      verifyNever(mockDatabaseHelper.updateExpense(any, any));
    });

    test('找不到支出時應回傳錯誤', () async {
      // Arrange
      when(mockDatabaseHelper.updateExpense(any, any))
          .thenAnswer((_) async => 0);

      // Act
      final result = await repository.updateExpense(testExpense);

      // Assert
      expect(result.isFailure, isTrue);
    });

    test('資料庫更新失敗時應回傳錯誤', () async {
      // Arrange
      when(mockDatabaseHelper.updateExpense(any, any))
          .thenThrow(Exception('DB error'));

      // Act
      final result = await repository.updateExpense(testExpense);

      // Assert
      expect(result.isFailure, isTrue);
    });
  });

  group('ExpenseRepository getExpenseById', () {
    test('取得支出成功', () async {
      // Arrange
      when(mockDatabaseHelper.getExpenseById(1))
          .thenAnswer((_) async => testExpenseMap);

      // Act
      final result = await repository.getExpenseById(1);

      // Assert
      expect(result.isSuccess, isTrue);
      final expense = result.getOrThrow();
      expect(expense.id, 1);
    });

    test('找不到支出時應回傳錯誤', () async {
      // Arrange
      when(mockDatabaseHelper.getExpenseById(999))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getExpenseById(999);

      // Assert
      expect(result.isFailure, isTrue);
    });

    test('資料庫查詢失敗時應回傳錯誤', () async {
      // Arrange
      when(mockDatabaseHelper.getExpenseById(any))
          .thenThrow(Exception('DB error'));

      // Act
      final result = await repository.getExpenseById(1);

      // Assert
      expect(result.isFailure, isTrue);
    });
  });

  group('ExpenseRepository getExpensesByMonth', () {
    test('取得月份支出成功', () async {
      // Arrange
      when(mockDatabaseHelper.getExpensesByMonth(
        year: anyNamed('year'),
        month: anyNamed('month'),
        includeDeleted: anyNamed('includeDeleted'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => [testExpenseMap]);

      // Act
      final result = await repository.getExpensesByMonth(
        year: 2025,
        month: 1,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      final expenses = result.getOrThrow();
      expect(expenses.length, 1);
    });

    test('資料庫查詢失敗時應回傳錯誤', () async {
      // Arrange
      when(mockDatabaseHelper.getExpensesByMonth(
        year: anyNamed('year'),
        month: anyNamed('month'),
        includeDeleted: anyNamed('includeDeleted'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenThrow(Exception('DB error'));

      // Act
      final result = await repository.getExpensesByMonth(
        year: 2025,
        month: 1,
      );

      // Assert
      expect(result.isFailure, isTrue);
    });
  });

  group('ExpenseRepository getMonthSummary', () {
    test('取得月份總計成功', () async {
      // Arrange
      when(mockDatabaseHelper.getMonthSummary(2025, 1)).thenAnswer(
        (_) async => {'total_count': 5, 'total_hkd_amount': 50000},
      );

      // Act
      final result = await repository.getMonthSummary(year: 2025, month: 1);

      // Assert
      expect(result.isSuccess, isTrue);
      final summary = result.getOrThrow();
      expect(summary.totalCount, 5);
      expect(summary.totalHkdAmountCents, 50000);
    });

    test('資料庫查詢失敗時應回傳錯誤', () async {
      // Arrange
      when(mockDatabaseHelper.getMonthSummary(any, any))
          .thenThrow(Exception('DB error'));

      // Act
      final result = await repository.getMonthSummary(year: 2025, month: 1);

      // Assert
      expect(result.isFailure, isTrue);
    });
  });

  group('ExpenseRepository softDeleteExpense', () {
    test('軟刪除支出成功', () async {
      // Arrange
      when(mockDatabaseHelper.getExpenseById(1))
          .thenAnswer((_) async => testExpenseMap);
      when(mockDatabaseHelper.updateExpense(any, any))
          .thenAnswer((_) async => 1);

      // Act
      final result = await repository.softDeleteExpense(1);

      // Assert
      expect(result.isSuccess, isTrue);
      verify(mockDatabaseHelper.updateExpense(1, any)).called(1);
    });

    test('找不到支出時應回傳錯誤', () async {
      // Arrange
      when(mockDatabaseHelper.getExpenseById(999))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.softDeleteExpense(999);

      // Assert
      expect(result.isFailure, isTrue);
    });
  });

  group('ExpenseRepository restoreExpense', () {
    test('還原支出成功', () async {
      // Arrange
      when(mockDatabaseHelper.updateExpense(any, any))
          .thenAnswer((_) async => 1);

      // Act
      final result = await repository.restoreExpense(1);

      // Assert
      expect(result.isSuccess, isTrue);
    });

    test('找不到支出時應回傳錯誤', () async {
      // Arrange
      when(mockDatabaseHelper.updateExpense(any, any))
          .thenAnswer((_) async => 0);

      // Act
      final result = await repository.restoreExpense(999);

      // Assert
      expect(result.isFailure, isTrue);
    });
  });

  group('ExpenseRepository getDeletedExpenses', () {
    test('取得已刪除支出成功', () async {
      // Arrange
      when(mockDatabaseHelper.getDeletedExpenses())
          .thenAnswer((_) async => [testExpenseMap]);

      // Act
      final result = await repository.getDeletedExpenses();

      // Assert
      expect(result.isSuccess, isTrue);
      final expenses = result.getOrThrow();
      expect(expenses.length, 1);
    });
  });

  group('ExpenseRepository permanentlyDeleteExpense', () {
    test('永久刪除支出成功', () async {
      // Arrange
      when(mockDatabaseHelper.getExpenseById(1))
          .thenAnswer((_) async => testExpenseMap);
      when(mockImageService.deleteImages(
        fullPath: anyNamed('fullPath'),
        thumbnailPath: anyNamed('thumbnailPath'),
      )).thenAnswer((_) async => Result.success(null));
      when(mockDatabaseHelper.deleteExpense(1)).thenAnswer((_) async => 1);

      // Act
      final result = await repository.permanentlyDeleteExpense(1);

      // Assert
      expect(result.isSuccess, isTrue);
      verify(mockDatabaseHelper.deleteExpense(1)).called(1);
    });

    test('找不到支出時應回傳錯誤', () async {
      // Arrange
      when(mockDatabaseHelper.getExpenseById(999))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.permanentlyDeleteExpense(999);

      // Assert
      expect(result.isFailure, isTrue);
    });
  });

  group('ExpenseRepository cleanupExpiredDeletedExpenses', () {
    test('清理過期已刪除支出成功', () async {
      // Arrange
      when(mockDatabaseHelper.getExpiredDeletedExpenses(any))
          .thenAnswer((_) async => [testExpenseMap]);
      when(mockDatabaseHelper.getExpenseById(1))
          .thenAnswer((_) async => testExpenseMap);
      when(mockImageService.deleteImages(
        fullPath: anyNamed('fullPath'),
        thumbnailPath: anyNamed('thumbnailPath'),
      )).thenAnswer((_) async => Result.success(null));
      when(mockDatabaseHelper.deleteExpense(1)).thenAnswer((_) async => 1);

      // Act
      final result = await repository.cleanupExpiredDeletedExpenses();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow(), 1);
    });

    test('無過期支出時回傳 0', () async {
      // Arrange
      when(mockDatabaseHelper.getExpiredDeletedExpenses(any))
          .thenAnswer((_) async => []);

      // Act
      final result = await repository.cleanupExpiredDeletedExpenses();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow(), 0);
    });
  });

  group('ExpenseRepository replaceReceiptImage', () {
    test('替換收據圖片成功', () async {
      // Arrange - getExpenseById stub needed
      when(mockDatabaseHelper.getExpenseById(1))
          .thenAnswer((_) async => testExpenseMap);

      // Act
      final result = await repository.replaceReceiptImage(
        expenseId: 1,
        newImagePath: '/temp/new_receipt.jpg',
      );

      // Assert
      expect(result.isSuccess, isTrue);
      final updated = result.getOrThrow();
      expect(updated.receiptImagePath, testImagePaths.fullPath);
    });

    test('找不到支出時應回傳錯誤', () async {
      // Arrange
      when(mockDatabaseHelper.getExpenseById(999))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.replaceReceiptImage(
        expenseId: 999,
        newImagePath: '/temp/new_receipt.jpg',
      );

      // Assert
      expect(result.isFailure, isTrue);
    });

    test('圖片處理失敗時應回傳錯誤', () async {
      // Arrange
      when(mockDatabaseHelper.getExpenseById(1))
          .thenAnswer((_) async => testExpenseMap);
      // Override processReceiptImage to fail
      when(mockImageService.processReceiptImage(
        sourcePath: anyNamed('sourcePath'),
        expenseDate: anyNamed('expenseDate'),
      )).thenAnswer((_) async =>
          Result.failure(const StorageException('Image processing failed')));

      // Act
      final result = await repository.replaceReceiptImage(
        expenseId: 1,
        newImagePath: '/temp/new_receipt.jpg',
      );

      // Assert
      expect(result.isFailure, isTrue);
    });
  });
}
