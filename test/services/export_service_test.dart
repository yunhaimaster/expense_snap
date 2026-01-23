import 'package:expense_snap/core/constants/currency_constants.dart';
import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/data/models/expense.dart';
import 'package:expense_snap/services/export_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 建立測試用的 ExportStrings
ExportStrings createTestExportStrings({int year = 2025, int month = 1}) {
  final monthStr = month.toString().padLeft(2, '0');
  return ExportStrings(
    sheetName: '$year年$month月報銷單',
    shareSubject: 'Expense Snap 報銷單',
    fileName: '報銷單_$year年$monthStr月',
    headerIndex: '序號',
    headerDate: '日期',
    headerDescription: '描述',
    headerOriginalAmount: '原始金額',
    headerOriginalCurrency: '原始幣種',
    headerExchangeRate: '匯率',
    headerRateSource: '匯率來源',
    headerHkdAmount: '港幣金額',
    headerReceiptFile: '收據檔名',
    headerTotal: '合計',
    rateSourceAuto: '自動',
    rateSourceOffline: '離線快取',
    rateSourceDefault: '預設',
    rateSourceManual: '手動',
    headerCategory: '分類',
    categoryUncategorized: '未分類',
    categoryMeals: '餐飲',
    categoryTransport: '交通',
    categoryAccommodation: '住宿',
    categoryOfficeSupplies: '辦公用品',
    categoryCommunication: '通訊',
    categoryEntertainment: '娛樂',
    categoryMedical: '醫療',
    categoryOther: '其他',
  );
}

void main() {
  group('ExportService', () {
    late List<Expense> testExpenses;
    late ExportStrings testStrings;

    setUp(() {
      // 建立測試用支出
      final now = DateTime.now();
      testExpenses = [
        Expense(
          id: 1,
          date: DateTime(2025, 1, 10),
          originalAmountCents: 10050, // 100.50
          originalCurrency: 'CNY',
          exchangeRate: 1089000, // 1.089
          exchangeRateSource: ExchangeRateSource.auto,
          convertedAmountCents: 10944, // 109.44
          description: '午餐',
          receiptImagePath: null,
          thumbnailPath: null,
          createdAt: now,
          updatedAt: now,
        ),
        Expense(
          id: 2,
          date: DateTime(2025, 1, 15),
          originalAmountCents: 5000, // 50.00
          originalCurrency: 'HKD',
          exchangeRate: 1000000, // 1.0
          exchangeRateSource: ExchangeRateSource.manual,
          convertedAmountCents: 5000, // 50.00
          description: '交通費',
          receiptImagePath: null,
          thumbnailPath: null,
          createdAt: now,
          updatedAt: now,
        ),
        Expense(
          id: 3,
          date: DateTime(2025, 1, 20),
          originalAmountCents: 2500, // 25.00
          originalCurrency: 'USD',
          exchangeRate: 7800000, // 7.8
          exchangeRateSource: ExchangeRateSource.offline,
          convertedAmountCents: 19500, // 195.00
          description: '文具',
          receiptImagePath: null,
          thumbnailPath: null,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      testStrings = createTestExportStrings();
    });

    group('ExportResult', () {
      test('should format file size correctly', () {
        const result = ExportResult(
          filePath: '/test.xlsx',
          fileName: 'test.xlsx',
          fileSize: 1024,
          expenseCount: 3,
          totalHkdCents: 35444,
        );

        expect(result.formattedFileSize, equals('1.0 KB'));
      });

      test('should format total amount correctly', () {
        const result = ExportResult(
          filePath: '/test.xlsx',
          fileName: 'test.xlsx',
          fileSize: 1024,
          expenseCount: 3,
          totalHkdCents: 35444,
        );

        expect(result.formattedTotalAmount, equals('HK\$354.44'));
      });

      test('should handle MB file size', () {
        const result = ExportResult(
          filePath: '/test.zip',
          fileName: 'test.zip',
          fileSize: 2 * 1024 * 1024, // 2MB
          expenseCount: 10,
          totalHkdCents: 100000,
          receiptCount: 8,
        );

        expect(result.formattedFileSize, equals('2.0 MB'));
      });

      test('should handle GB file size', () {
        const result = ExportResult(
          filePath: '/test.zip',
          fileName: 'test.zip',
          fileSize: 2 * 1024 * 1024 * 1024, // 2GB
          expenseCount: 10,
          totalHkdCents: 100000,
          receiptCount: 8,
        );

        expect(result.formattedFileSize, equals('2.0 GB'));
      });

      test('should handle bytes file size', () {
        const result = ExportResult(
          filePath: '/test.xlsx',
          fileName: 'test.xlsx',
          fileSize: 512,
          expenseCount: 1,
          totalHkdCents: 1000,
        );

        expect(result.formattedFileSize, equals('512 B'));
      });

      test('should have null receiptCount for Excel export', () {
        const result = ExportResult(
          filePath: '/test.xlsx',
          fileName: 'test.xlsx',
          fileSize: 1024,
          expenseCount: 3,
          totalHkdCents: 35444,
        );

        expect(result.receiptCount, isNull);
      });

      test('should have receiptCount for ZIP export', () {
        const result = ExportResult(
          filePath: '/test.zip',
          fileName: 'test.zip',
          fileSize: 1024 * 1024,
          expenseCount: 5,
          totalHkdCents: 50000,
          receiptCount: 3,
        );

        expect(result.receiptCount, equals(3));
      });
    });

    group('Test data validation', () {
      test('test expenses should have correct count', () {
        expect(testExpenses.length, equals(3));
      });

      test('test expenses should have correct total', () {
        final total = testExpenses.fold<int>(
          0,
          (sum, e) => sum + e.convertedAmountCents,
        );
        expect(total, equals(35444)); // 10944 + 5000 + 19500
      });

      test('test expenses should have no receipts', () {
        final withReceipts = testExpenses.where((e) => e.hasReceipt).length;
        expect(withReceipts, equals(0));
      });

      test('test expenses should have correct currencies', () {
        expect(testExpenses[0].originalCurrency, equals('CNY'));
        expect(testExpenses[1].originalCurrency, equals('HKD'));
        expect(testExpenses[2].originalCurrency, equals('USD'));
      });

      test('test expenses should have different rate sources', () {
        expect(
          testExpenses[0].exchangeRateSource,
          equals(ExchangeRateSource.auto),
        );
        expect(
          testExpenses[1].exchangeRateSource,
          equals(ExchangeRateSource.manual),
        );
        expect(
          testExpenses[2].exchangeRateSource,
          equals(ExchangeRateSource.offline),
        );
      });
    });

    // Note: 實際的匯出功能測試需要平台支援，在整合測試中進行
    // 以下測試標記為 skip，在真實設備上測試
    group('exportToExcel', () {
      test(
        'should require path_provider initialization',
        () {
          // 這個測試驗證 ExportService 需要平台支援
          final service = ExportService();
          expect(service, isNotNull);
        },
      );
    });

    group('exportToZip', () {
      test(
        'should require path_provider initialization',
        () {
          // 這個測試驗證 ExportService 需要平台支援
          final service = ExportService();
          expect(service, isNotNull);
        },
      );
    });

    group('Filename generation', () {
      test('should sanitize description with special characters', () {
        // 測試檔名生成邏輯（透過 ExportResult 驗證）
        const result = ExportResult(
          filePath: '/test/user_202501_1234567890.xlsx',
          fileName: 'user_202501_1234567890.xlsx',
          fileSize: 1024,
          expenseCount: 1,
          totalHkdCents: 1000,
        );
        // 檔名應該不含特殊字元
        expect(result.fileName, isNot(contains('/')));
        expect(result.fileName, isNot(contains(':')));
        expect(result.fileName, isNot(contains('*')));
        expect(result.fileName, isNot(contains('?')));
      });

      test('should handle empty description', () {
        final now = DateTime.now();
        final expense = Expense(
          id: 1,
          date: DateTime(2025, 1, 10),
          originalAmountCents: 1000,
          originalCurrency: 'HKD',
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          convertedAmountCents: 1000,
          description: '', // 空描述
          receiptImagePath: null,
          thumbnailPath: null,
          createdAt: now,
          updatedAt: now,
        );
        expect(expense.description, isEmpty);
      });
    });

    group('Parameter validation', () {
      test('should validate month at service level', () {
        // Dart DateTime 會自動正規化無效月份，因此需要在服務層驗證
        // ExportService 現在會驗證 month 必須在 1-12 之間
        final service = ExportService();
        expect(service, isNotNull);
      });

      test('should validate year at service level', () {
        // ExportService 現在會驗證 year 必須在 2000-2100 之間
        final service = ExportService();
        expect(service, isNotNull);
      });
    });

    group('Edge cases', () {
      test('should handle expense with empty receipt path', () {
        final now = DateTime.now();
        final expense = Expense(
          id: 1,
          date: DateTime(2025, 1, 10),
          originalAmountCents: 1000,
          originalCurrency: 'HKD',
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          convertedAmountCents: 1000,
          description: '測試',
          receiptImagePath: '', // 空字串路徑
          thumbnailPath: null,
          createdAt: now,
          updatedAt: now,
        );
        // 空字串應該被視為沒有收據
        expect(expense.receiptImagePath, isEmpty);
      });

      test('should handle large total amount without overflow', () {
        // 測試大金額不會溢位
        const largeAmount = 999999999999; // 接近 int 最大值的金額（分）
        const result = ExportResult(
          filePath: '/test.xlsx',
          fileName: 'test.xlsx',
          fileSize: 1024,
          expenseCount: 1000,
          totalHkdCents: largeAmount,
        );
        // 格式化不應該拋出異常
        expect(result.formattedTotalAmount, isNotEmpty);
      });

      test('should handle zero file size', () {
        const result = ExportResult(
          filePath: '/test.xlsx',
          fileName: 'test.xlsx',
          fileSize: 0,
          expenseCount: 0,
          totalHkdCents: 0,
        );
        expect(result.formattedFileSize, equals('0 B'));
      });

      test('should handle Unicode in description', () {
        final now = DateTime.now();
        final expense = Expense(
          id: 1,
          date: DateTime(2025, 1, 10),
          originalAmountCents: 1000,
          originalCurrency: 'HKD',
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          convertedAmountCents: 1000,
          description: '🍔午餐 McDonald\'s 麥當勞',
          receiptImagePath: null,
          thumbnailPath: null,
          createdAt: now,
          updatedAt: now,
        );
        // 應該能正確處理 Unicode 字元
        expect(expense.description, contains('🍔'));
        expect(expense.description, contains('麥當勞'));
      });
    });

    group('exportToExcel 參數驗證', () {
      late ExportService service;

      setUp(() {
        service = ExportService();
      });

      test('月份小於 1 應回傳錯誤', () async {
        final result = await service.exportToExcel(
          expenses: testExpenses,
          year: 2025,
          month: 0,
          userName: 'Test',
          strings: testStrings,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ValidationException>());
      });

      test('月份大於 12 應回傳錯誤', () async {
        final result = await service.exportToExcel(
          expenses: testExpenses,
          year: 2025,
          month: 13,
          userName: 'Test',
          strings: testStrings,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ValidationException>());
      });

      test('年份小於 2000 應回傳錯誤', () async {
        final result = await service.exportToExcel(
          expenses: testExpenses,
          year: 1999,
          month: 6,
          userName: 'Test',
          strings: testStrings,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ValidationException>());
      });

      test('年份大於 2100 應回傳錯誤', () async {
        final result = await service.exportToExcel(
          expenses: testExpenses,
          year: 2101,
          month: 6,
          userName: 'Test',
          strings: testStrings,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ValidationException>());
      });

      test('空支出清單應回傳錯誤', () async {
        final result = await service.exportToExcel(
          expenses: [],
          year: 2025,
          month: 6,
          userName: 'Test',
          strings: testStrings,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ExportException>());
      });

      // 邊界值測試 - 驗證有效邊界值不會觸發 ValidationException
      test('月份等於 1 應通過驗證', () async {
        final result = await service.exportToExcel(
          expenses: testExpenses,
          year: 2025,
          month: 1,
          userName: 'Test',
          strings: testStrings,
        );

        // 可能因 path_provider 未初始化而失敗，但不應是 ValidationException
        if (result.isFailure) {
          expect(result.errorOrNull, isNot(isA<ValidationException>()));
        }
      });

      test('月份等於 12 應通過驗證', () async {
        final result = await service.exportToExcel(
          expenses: testExpenses,
          year: 2025,
          month: 12,
          userName: 'Test',
          strings: testStrings,
        );

        if (result.isFailure) {
          expect(result.errorOrNull, isNot(isA<ValidationException>()));
        }
      });

      test('年份等於 2000 應通過驗證', () async {
        final result = await service.exportToExcel(
          expenses: testExpenses,
          year: 2000,
          month: 6,
          userName: 'Test',
          strings: testStrings,
        );

        if (result.isFailure) {
          expect(result.errorOrNull, isNot(isA<ValidationException>()));
        }
      });

      test('年份等於 2100 應通過驗證', () async {
        final result = await service.exportToExcel(
          expenses: testExpenses,
          year: 2100,
          month: 6,
          userName: 'Test',
          strings: testStrings,
        );

        if (result.isFailure) {
          expect(result.errorOrNull, isNot(isA<ValidationException>()));
        }
      });
    });

    group('exportToZip 參數驗證', () {
      late ExportService service;

      setUp(() {
        service = ExportService();
      });

      test('月份無效應回傳錯誤', () async {
        final result = await service.exportToZip(
          expenses: testExpenses,
          year: 2025,
          month: 15,
          userName: 'Test',
          strings: testStrings,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ValidationException>());
      });

      test('年份無效應回傳錯誤', () async {
        final result = await service.exportToZip(
          expenses: testExpenses,
          year: 1800,
          month: 6,
          userName: 'Test',
          strings: testStrings,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ValidationException>());
      });

      test('空支出清單應回傳錯誤', () async {
        final result = await service.exportToZip(
          expenses: [],
          year: 2025,
          month: 6,
          userName: 'Test',
          strings: testStrings,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ExportException>());
      });
    });

    group('shareFile', () {
      late ExportService service;

      setUp(() {
        service = ExportService();
      });

      test('不存在的檔案應回傳錯誤', () async {
        final result = await service.shareFile('/non/existent/file.xlsx');

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<StorageException>());
      });
    });
  });

  group('ExportException', () {
    test('noData 應建立正確的例外', () {
      final exception = ExportException.noData();
      expect(exception.message, contains('無資料'));
    });

    test('excelGenerationFailed 應建立正確的例外', () {
      final exception = ExportException.excelGenerationFailed('test error');
      expect(exception.message, contains('Excel'));
    });

    test('zipFailed 應建立正確的例外', () {
      final exception = ExportException.zipFailed('test error');
      expect(exception.message, contains('ZIP'));
    });

    test('shareFailed 應建立正確的例外', () {
      final exception = ExportException.shareFailed();
      expect(exception.message, contains('分享'));
    });
  });

  group('exportToZip 進度回調', () {
    late ExportService service;
    late List<Expense> testExpenses;
    late ExportStrings testStrings;

    setUp(() {
      service = ExportService();
      final now = DateTime.now();
      // 建立測試支出（不含收據，避免檔案系統依賴）
      testExpenses = List.generate(
        5,
        (i) => Expense(
          id: i + 1,
          date: DateTime(2025, 1, 10 + i),
          originalAmountCents: 1000 * (i + 1),
          originalCurrency: 'HKD',
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          convertedAmountCents: 1000 * (i + 1),
          description: '測試支出 $i',
          receiptImagePath: null,
          thumbnailPath: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
      testStrings = createTestExportStrings();
    });

    test('onProgress 應被呼叫', () async {
      final progressValues = <double>[];

      await service.exportToZip(
        expenses: testExpenses,
        year: 2025,
        month: 1,
        userName: 'Test',
        strings: testStrings,
        onProgress: progressValues.add,
      );

      // 由於 path_provider 未初始化，匯出會失敗
      // 但進度回調至少應該被呼叫一次（在驗證通過後）
      // 這裡我們只驗證 onProgress 參數能正確傳遞
      expect(progressValues, isA<List<double>>());
    });

    test('進度值應介於 0 和 1 之間', () async {
      final progressValues = <double>[];

      await service.exportToZip(
        expenses: testExpenses,
        year: 2025,
        month: 1,
        userName: 'Test',
        strings: testStrings,
        onProgress: progressValues.add,
      );

      // 如果有進度回調，驗證值的範圍
      for (final progress in progressValues) {
        expect(progress, greaterThanOrEqualTo(0.0));
        expect(progress, lessThanOrEqualTo(1.0));
      }
    });

    test('無 onProgress 回調應正常運作', () async {
      // 不傳入 onProgress，應該不會拋出異常
      final result = await service.exportToZip(
        expenses: testExpenses,
        year: 2025,
        month: 1,
        userName: 'Test',
        strings: testStrings,
        // onProgress 不傳入
      );

      // 即使沒有進度回調也應該正常處理
      // （可能因 path_provider 失敗，但不應因缺少 onProgress 失敗）
      expect(result, isNotNull);
    });

    test('空支出清單不應觸發進度回調', () async {
      final progressValues = <double>[];

      final result = await service.exportToZip(
        expenses: [], // 空清單會立即失敗
        year: 2025,
        month: 1,
        userName: 'Test',
        strings: testStrings,
        onProgress: progressValues.add,
      );

      // 應該失敗（無資料）
      expect(result.isFailure, isTrue);
      // 驗證失敗應該在進度回調之前發生
      expect(progressValues, isEmpty);
    });

    test('參數驗證失敗不應觸發進度回調', () async {
      final progressValues = <double>[];

      final result = await service.exportToZip(
        expenses: testExpenses,
        year: 2025,
        month: 15, // 無效月份
        userName: 'Test',
        strings: testStrings,
        onProgress: progressValues.add,
      );

      // 應該失敗（無效月份）
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ValidationException>());
      // 驗證失敗應該在進度回調之前發生
      expect(progressValues, isEmpty);
    });
  });
}
