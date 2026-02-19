import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expense_snap/core/services/quick_input_service.dart';

/// 測試用 QuickInputService，注入可測試的資料庫
///
/// 因為 QuickInputService 使用 DatabaseHelper.instance（單例），
/// 我們用 sqflite_ffi 在記憶體中建立測試資料庫
class TestableQuickInputService {
  TestableQuickInputService(this._db);
  final Database _db;

  static const int maxRecentDescriptions = 10;

  /// 轉義 LIKE 模式中的特殊字元（複製自 QuickInputService）
  String escapeLikePattern(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
  }

  /// 搜尋描述
  Future<List<String>> searchDescriptions(String query) async {
    if (query.isEmpty) return [];

    final escapedQuery = escapeLikePattern(query);

    final result = await _db.rawQuery(
      '''
      SELECT DISTINCT description
      FROM expenses
      WHERE deleted_at IS NULL
        AND description IS NOT NULL
        AND description LIKE ? ESCAPE '\\'
      ORDER BY created_at DESC
      LIMIT ?
    ''',
      ['%$escapedQuery%', maxRecentDescriptions],
    );

    return result
        .map((row) => row['description'] as String?)
        .where((desc) => desc != null && desc.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// 取得最近描述
  Future<List<String>> getRecentDescriptions() async {
    final result = await _db.rawQuery(
      '''
      SELECT DISTINCT description
      FROM expenses
      WHERE deleted_at IS NULL AND description IS NOT NULL AND description != ''
      ORDER BY created_at DESC
      LIMIT ?
    ''',
      [maxRecentDescriptions],
    );

    return result
        .map((row) => row['description'] as String?)
        .where((desc) => desc != null && desc.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// 取得常用幣種
  Future<List<String>> getRecentCurrencies() async {
    final result = await _db.rawQuery('''
      SELECT original_currency, COUNT(*) as count
      FROM expenses
      WHERE deleted_at IS NULL AND original_currency IS NOT NULL
      GROUP BY original_currency
      ORDER BY count DESC
    ''');

    return result
        .map((row) => row['original_currency'] as String?)
        .where((currency) => currency != null && currency.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// 取得常用金額
  Future<List<int>> getCommonAmounts() async {
    final result = await _db.rawQuery('''
      SELECT hkd_amount, COUNT(*) as count
      FROM expenses
      WHERE deleted_at IS NULL AND hkd_amount IS NOT NULL
      GROUP BY hkd_amount
      ORDER BY count DESC
      LIMIT 5
    ''');

    return result
        .map((row) => row['hkd_amount'] as int?)
        .where((amount) => amount != null)
        .cast<int>()
        .toList();
  }
}

void main() {
  // 初始化 sqflite_ffi
  sqfliteFfiInit();

  late Database db;
  late TestableQuickInputService service;

  setUp(() async {
    // 建立記憶體中的測試資料庫
    databaseFactory = databaseFactoryFfi;
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            original_amount INTEGER NOT NULL,
            original_currency TEXT NOT NULL,
            exchange_rate INTEGER NOT NULL,
            exchange_rate_source TEXT NOT NULL,
            hkd_amount INTEGER NOT NULL,
            description TEXT NOT NULL,
            category TEXT,
            target_currency TEXT NOT NULL DEFAULT 'HKD',
            receipt_image_path TEXT,
            thumbnail_path TEXT,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            deleted_at TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );

    service = TestableQuickInputService(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// 插入測試支出
  Future<void> insertExpense({
    required String description,
    String currency = 'HKD',
    int amount = 1000,
    String? deletedAt,
    required String createdAt,
  }) async {
    await db.insert('expenses', {
      'date': '2025-01-10',
      'original_amount': amount,
      'original_currency': currency,
      'exchange_rate': 1000000,
      'exchange_rate_source': 'auto',
      'hkd_amount': amount,
      'description': description,
      'target_currency': 'HKD',
      'is_deleted': deletedAt != null ? 1 : 0,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': createdAt,
    });
  }

  group('QuickInputService', () {
    group('instance', () {
      test('應為單例模式', () {
        final instance1 = QuickInputService.instance;
        final instance2 = QuickInputService.instance;
        expect(identical(instance1, instance2), isTrue);
      });

      test('maxRecentDescriptions 應為 10', () {
        expect(QuickInputService.maxRecentDescriptions, equals(10));
      });
    });

    group('escapeLikePattern', () {
      test('應轉義百分號 %', () {
        final result = service.escapeLikePattern('100% 折扣');
        expect(result, equals('100\\% 折扣'));
      });

      test('應轉義底線 _', () {
        final result = service.escapeLikePattern('file_name');
        expect(result, equals('file\\_name'));
      });

      test('應轉義反斜線 \\', () {
        final result = service.escapeLikePattern('path\\to\\file');
        expect(result, equals('path\\\\to\\\\file'));
      });

      test('應同時轉義多個特殊字元', () {
        final result = service.escapeLikePattern('50% off_sale\\deal');
        expect(result, equals('50\\% off\\_sale\\\\deal'));
      });

      test('無特殊字元時應原樣回傳', () {
        final result = service.escapeLikePattern('午餐費用');
        expect(result, equals('午餐費用'));
      });

      test('空字串應原樣回傳', () {
        final result = service.escapeLikePattern('');
        expect(result, equals(''));
      });

      test('連續特殊字元應全部轉義', () {
        final result = service.escapeLikePattern('%%__\\\\');
        expect(result, equals('\\%\\%\\_\\_\\\\\\\\'));
      });
    });

    group('searchDescriptions', () {
      test('空查詢應回傳空列表', () async {
        final result = await service.searchDescriptions('');
        expect(result, isEmpty);
      });

      test('應找到匹配的描述', () async {
        await insertExpense(
          description: '午餐',
          createdAt: '2025-01-10T10:00:00',
        );
        await insertExpense(
          description: '晚餐',
          createdAt: '2025-01-10T11:00:00',
        );
        await insertExpense(
          description: '午餐便當',
          createdAt: '2025-01-10T12:00:00',
        );

        final result = await service.searchDescriptions('午餐');

        expect(result, contains('午餐'));
        expect(result, contains('午餐便當'));
        expect(result, isNot(contains('晚餐')));
      });

      test('不應回傳已軟刪除的記錄', () async {
        await insertExpense(
          description: '午餐',
          createdAt: '2025-01-10T10:00:00',
        );
        await insertExpense(
          description: '已刪除午餐',
          createdAt: '2025-01-10T11:00:00',
          deletedAt: '2025-01-11T10:00:00',
        );

        final result = await service.searchDescriptions('午餐');

        expect(result, contains('午餐'));
        expect(result, isNot(contains('已刪除午餐')));
      });

      test('結果數量不應超過 maxRecentDescriptions', () async {
        // 插入超過限制的記錄
        for (int i = 0; i < 15; i++) {
          await insertExpense(
            description: '支出項目$i',
            createdAt:
                '2025-01-${(10 + i).toString().padLeft(2, '0')}T10:00:00',
          );
        }

        final result = await service.searchDescriptions('支出');
        expect(result.length, lessThanOrEqualTo(10));
      });

      test('含 LIKE 特殊字元的查詢應被正確轉義', () async {
        await insertExpense(
          description: '50% 折扣',
          createdAt: '2025-01-10T10:00:00',
        );
        await insertExpense(
          description: '50元',
          createdAt: '2025-01-10T11:00:00',
        );

        // 搜尋 "50%" 不應匹配 "50元"（因為 % 被轉義了）
        final result = await service.searchDescriptions('50%');

        expect(result, contains('50% 折扣'));
        // "50元" 不包含字面 "50%"，所以不應被匹配
        expect(result, isNot(contains('50元')));
      });

      test('含底線的查詢應精確匹配', () async {
        await insertExpense(
          description: 'file_name.pdf',
          createdAt: '2025-01-10T10:00:00',
        );
        await insertExpense(
          description: 'filename.pdf',
          createdAt: '2025-01-10T11:00:00',
        );

        final result = await service.searchDescriptions('file_name');

        expect(result, contains('file_name.pdf'));
        // "filename.pdf" 不包含 "file_name"，不應被匹配
        expect(result, isNot(contains('filename.pdf')));
      });

      test('回傳的描述應為不重複的', () async {
        // 插入相同描述的多筆記錄
        await insertExpense(
          description: '午餐',
          createdAt: '2025-01-10T10:00:00',
        );
        await insertExpense(
          description: '午餐',
          createdAt: '2025-01-11T10:00:00',
        );
        await insertExpense(
          description: '午餐',
          createdAt: '2025-01-12T10:00:00',
        );

        final result = await service.searchDescriptions('午餐');

        // DISTINCT 應確保只有一個 "午餐"
        final lunchCount = result.where((d) => d == '午餐').length;
        expect(lunchCount, equals(1));
      });
    });

    group('getRecentDescriptions', () {
      test('無資料時應回傳空列表', () async {
        final result = await service.getRecentDescriptions();
        expect(result, isEmpty);
      });

      test('應回傳最近的描述', () async {
        await insertExpense(
          description: '早餐',
          createdAt: '2025-01-08T10:00:00',
        );
        await insertExpense(
          description: '午餐',
          createdAt: '2025-01-09T10:00:00',
        );
        await insertExpense(
          description: '晚餐',
          createdAt: '2025-01-10T10:00:00',
        );

        final result = await service.getRecentDescriptions();

        expect(result.length, equals(3));
        // 按 created_at DESC 排序，最新的在前
        expect(result.first, equals('晚餐'));
      });

      test('不應包含已軟刪除的記錄', () async {
        await insertExpense(
          description: '正常支出',
          createdAt: '2025-01-10T10:00:00',
        );
        await insertExpense(
          description: '已刪除支出',
          createdAt: '2025-01-11T10:00:00',
          deletedAt: '2025-01-12T10:00:00',
        );

        final result = await service.getRecentDescriptions();
        expect(result, contains('正常支出'));
        expect(result, isNot(contains('已刪除支出')));
      });

      test('不應包含空描述', () async {
        await insertExpense(description: '', createdAt: '2025-01-10T10:00:00');
        await insertExpense(
          description: '午餐',
          createdAt: '2025-01-11T10:00:00',
        );

        final result = await service.getRecentDescriptions();
        expect(result, isNot(contains('')));
        expect(result, contains('午餐'));
      });
    });

    group('getRecentCurrencies', () {
      test('無資料時應回傳空列表', () async {
        final result = await service.getRecentCurrencies();
        expect(result, isEmpty);
      });

      test('應按使用頻率排序', () async {
        // HKD 出現 3 次，USD 出現 1 次
        await insertExpense(
          description: '支出1',
          currency: 'HKD',
          createdAt: '2025-01-10T10:00:00',
        );
        await insertExpense(
          description: '支出2',
          currency: 'HKD',
          createdAt: '2025-01-11T10:00:00',
        );
        await insertExpense(
          description: '支出3',
          currency: 'HKD',
          createdAt: '2025-01-12T10:00:00',
        );
        await insertExpense(
          description: '支出4',
          currency: 'USD',
          createdAt: '2025-01-13T10:00:00',
        );

        final result = await service.getRecentCurrencies();

        expect(result.length, equals(2));
        // HKD 使用頻率高，應排在第一位
        expect(result.first, equals('HKD'));
        expect(result.last, equals('USD'));
      });

      test('不應包含已軟刪除的記錄', () async {
        await insertExpense(
          description: '支出',
          currency: 'JPY',
          createdAt: '2025-01-10T10:00:00',
          deletedAt: '2025-01-11T10:00:00',
        );

        final result = await service.getRecentCurrencies();
        expect(result, isNot(contains('JPY')));
      });
    });

    group('getCommonAmounts', () {
      test('無資料時應回傳空列表', () async {
        final result = await service.getCommonAmounts();
        expect(result, isEmpty);
      });

      test('應按使用頻率排序，最多 5 筆', () async {
        // 1000 出現 3 次，5000 出現 2 次，2000 出現 1 次
        for (int i = 0; i < 3; i++) {
          await insertExpense(
            description: '支出',
            amount: 1000,
            createdAt: '2025-01-${10 + i}T10:00:00',
          );
        }
        for (int i = 0; i < 2; i++) {
          await insertExpense(
            description: '支出',
            amount: 5000,
            createdAt: '2025-01-${15 + i}T10:00:00',
          );
        }
        await insertExpense(
          description: '支出',
          amount: 2000,
          createdAt: '2025-01-20T10:00:00',
        );

        final result = await service.getCommonAmounts();

        expect(result.length, equals(3));
        // 頻率最高的排在前面
        expect(result.first, equals(1000));
        expect(result[1], equals(5000));
      });

      test('結果最多 5 筆', () async {
        // 插入 7 種不同金額
        for (int i = 0; i < 7; i++) {
          await insertExpense(
            description: '支出',
            amount: (i + 1) * 1000,
            createdAt: '2025-01-${10 + i}T10:00:00',
          );
        }

        final result = await service.getCommonAmounts();
        expect(result.length, lessThanOrEqualTo(5));
      });
    });
  });
}
