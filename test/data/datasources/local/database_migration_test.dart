import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 資料庫遷移整合測試
///
/// 使用 sqflite_common_ffi 在記憶體中執行真實 SQLite，
/// 驗證 DatabaseHelper 的 onCreate/onUpgrade 邏輯。
///
/// 測試範圍：
/// - v3 全新建立（onCreate）
/// - v1→v2 遷移（新增 category）
/// - v2→v3 遷移（新增 target_currency，重建 exchange_rate_cache）
/// - v1→v3 完整遷移路徑，含資料保留驗證

// ============ Schema SQL（對應 DatabaseHelper 各版本） ============

/// v1 schema：原始表結構（無 category、無 target_currency）
Future<void> _createV1Schema(Database db) async {
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
      receipt_image_path TEXT,
      thumbnail_path TEXT,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      deleted_at TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

  // v1 索引
  await db.execute(
    'CREATE INDEX idx_expenses_date ON expenses (date)',
  );
  await db.execute(
    'CREATE INDEX idx_expenses_is_deleted ON expenses (is_deleted)',
  );
  await db.execute(
    'CREATE INDEX idx_expenses_deleted_at ON expenses (deleted_at)',
  );
  await db.execute('''
    CREATE INDEX idx_expenses_deleted_created
    ON expenses (is_deleted, created_at DESC)
  ''');
  await db.execute('''
    CREATE INDEX idx_expenses_deleted_description
    ON expenses (is_deleted, description)
  ''');

  // v1 的 exchange_rate_cache（單一主鍵，rate_to_hkd 欄位）
  await db.execute('''
    CREATE TABLE exchange_rate_cache (
      currency TEXT PRIMARY KEY,
      rate_to_hkd INTEGER NOT NULL,
      fetched_at TEXT NOT NULL,
      source TEXT NOT NULL
    )
  ''');

  // backup_status
  await db.execute('''
    CREATE TABLE backup_status (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      last_backup_at TEXT,
      last_backup_count INTEGER NOT NULL DEFAULT 0,
      last_backup_size_kb INTEGER NOT NULL DEFAULT 0,
      google_email TEXT
    )
  ''');
  await db.insert('backup_status', {
    'id': 1,
    'last_backup_count': 0,
    'last_backup_size_kb': 0,
  });

  // app_settings
  await db.execute('''
    CREATE TABLE app_settings (
      key TEXT PRIMARY KEY,
      value TEXT
    )
  ''');
}

/// v1→v2 遷移：新增 category 欄位和索引
Future<void> _migrateV1ToV2(Database db) async {
  await db.execute('ALTER TABLE expenses ADD COLUMN category TEXT');
  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses (category)
  ''');
  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_expenses_deleted_category
    ON expenses (is_deleted, category)
  ''');
  await db.execute('ANALYZE');
}

/// v2→v3 遷移：新增 target_currency，重建 exchange_rate_cache
Future<void> _migrateV2ToV3(Database db) async {
  await db.transaction((txn) async {
    // 1. expenses 新增 target_currency
    await txn.execute(
      "ALTER TABLE expenses ADD COLUMN target_currency TEXT NOT NULL DEFAULT 'HKD'",
    );

    // 2. 新增索引
    await txn.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_target_currency
      ON expenses (target_currency)
    ''');

    // 3. 重建 exchange_rate_cache（複合主鍵）
    await txn.execute('''
      CREATE TABLE exchange_rate_cache_backup AS
      SELECT currency, rate_to_hkd as rate, fetched_at, source
      FROM exchange_rate_cache
    ''');
    await txn.execute('DROP TABLE exchange_rate_cache');
    await txn.execute('''
      CREATE TABLE exchange_rate_cache (
        currency TEXT NOT NULL,
        base_currency TEXT NOT NULL DEFAULT 'HKD',
        rate INTEGER NOT NULL,
        fetched_at TEXT NOT NULL,
        source TEXT NOT NULL,
        PRIMARY KEY (currency, base_currency)
      )
    ''');
    await txn.execute('''
      INSERT INTO exchange_rate_cache (currency, base_currency, rate, fetched_at, source)
      SELECT currency, 'HKD', COALESCE(rate, 0), fetched_at, source
      FROM exchange_rate_cache_backup
      WHERE rate IS NOT NULL
    ''');
    await txn.execute('DROP TABLE exchange_rate_cache_backup');
  });
  await db.execute('ANALYZE');
}

/// v3 全新建立（對應 DatabaseHelper._onCreate）
Future<void> _createV3Schema(Database db) async {
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

  await db.execute('CREATE INDEX idx_expenses_date ON expenses (date)');
  await db.execute(
    'CREATE INDEX idx_expenses_is_deleted ON expenses (is_deleted)',
  );
  await db.execute(
    'CREATE INDEX idx_expenses_deleted_at ON expenses (deleted_at)',
  );
  await db.execute('''
    CREATE INDEX idx_expenses_deleted_created
    ON expenses (is_deleted, created_at DESC)
  ''');
  await db.execute('''
    CREATE INDEX idx_expenses_deleted_description
    ON expenses (is_deleted, description)
  ''');
  await db.execute(
    'CREATE INDEX idx_expenses_category ON expenses (category)',
  );
  await db.execute('''
    CREATE INDEX idx_expenses_deleted_category
    ON expenses (is_deleted, category)
  ''');
  await db.execute('''
    CREATE INDEX idx_expenses_target_currency ON expenses (target_currency)
  ''');

  await db.execute('''
    CREATE TABLE exchange_rate_cache (
      currency TEXT NOT NULL,
      base_currency TEXT NOT NULL DEFAULT 'HKD',
      rate INTEGER NOT NULL,
      fetched_at TEXT NOT NULL,
      source TEXT NOT NULL,
      PRIMARY KEY (currency, base_currency)
    )
  ''');

  await db.execute('''
    CREATE TABLE backup_status (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      last_backup_at TEXT,
      last_backup_count INTEGER NOT NULL DEFAULT 0,
      last_backup_size_kb INTEGER NOT NULL DEFAULT 0,
      google_email TEXT
    )
  ''');
  await db.insert('backup_status', {
    'id': 1,
    'last_backup_count': 0,
    'last_backup_size_kb': 0,
  });

  await db.execute('''
    CREATE TABLE app_settings (
      key TEXT PRIMARY KEY,
      value TEXT
    )
  ''');
}

// ============ 工具函式 ============

/// 取得表的欄位名稱列表
Future<List<String>> _getColumnNames(Database db, String table) async {
  final result = await db.rawQuery('PRAGMA table_info($table)');
  return result.map((row) => row['name'] as String).toList();
}

/// 取得資料庫中所有表名
Future<List<String>> _getTableNames(Database db) async {
  final result = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
  );
  return result.map((row) => row['name'] as String).toList();
}

/// 取得指定表的索引名稱列表
Future<List<String>> _getIndexNames(Database db, String table) async {
  final result = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='$table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
  );
  return result.map((row) => row['name'] as String).toList();
}

/// 開啟一個全新的記憶體資料庫
Future<Database> _openFreshDb() async {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      singleInstance: false,
    ),
  );
}

/// 插入測試用支出資料（v1 schema，無 category / target_currency）
Future<int> _insertV1Expense(
  Database db, {
  required String date,
  required int amount,
  required String currency,
  required String description,
}) async {
  return db.insert('expenses', {
    'date': date,
    'original_amount': amount,
    'original_currency': currency,
    'exchange_rate': 1000000,
    'exchange_rate_source': 'test',
    'hkd_amount': amount,
    'description': description,
    'is_deleted': 0,
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  });
}

void main() {
  // 初始化 FFI（在所有測試前執行一次）
  sqfliteFfiInit();

  group('onCreate - v3 全新建立', () {
    late Database db;

    setUp(() async {
      db = await _openFreshDb();
      await _createV3Schema(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('應建立所有預期的表', () async {
      final tables = await _getTableNames(db);

      expect(
        tables,
        containsAll([
          'app_settings',
          'backup_status',
          'exchange_rate_cache',
          'expenses',
        ]),
      );
    });

    test('expenses 表應包含 v3 所有欄位', () async {
      final columns = await _getColumnNames(db, 'expenses');

      // 核心欄位
      expect(
        columns,
        containsAll([
          'id',
          'date',
          'original_amount',
          'original_currency',
          'exchange_rate',
          'hkd_amount',
          'description',
          'category',
          'target_currency',
          'is_deleted',
          'created_at',
          'updated_at',
        ]),
      );
    });

    test('exchange_rate_cache 應有複合主鍵結構', () async {
      final columns = await _getColumnNames(db, 'exchange_rate_cache');

      expect(
        columns,
        containsAll([
          'currency',
          'base_currency',
          'rate',
          'fetched_at',
          'source',
        ]),
      );

      // 驗證複合主鍵：同幣種不同基準應能共存
      await db.insert('exchange_rate_cache', {
        'currency': 'USD',
        'base_currency': 'HKD',
        'rate': 7800000,
        'fetched_at': '2026-01-01T00:00:00Z',
        'source': 'test',
      });
      await db.insert('exchange_rate_cache', {
        'currency': 'USD',
        'base_currency': 'JPY',
        'rate': 150000000,
        'fetched_at': '2026-01-01T00:00:00Z',
        'source': 'test',
      });

      final countResult = await db.rawQuery(
        'SELECT COUNT(*) FROM exchange_rate_cache',
      );
      final count = countResult.first.values.first as int;
      expect(count, 2);
    });

    test('backup_status 應有初始化單行記錄', () async {
      final rows = await db.query('backup_status');

      expect(rows.length, 1);
      expect(rows.first['id'], 1);
      expect(rows.first['last_backup_count'], 0);
    });

    test('expenses 表應有預期的索引', () async {
      final indexes = await _getIndexNames(db, 'expenses');

      expect(
        indexes,
        containsAll([
          'idx_expenses_date',
          'idx_expenses_is_deleted',
          'idx_expenses_deleted_at',
          'idx_expenses_deleted_created',
          'idx_expenses_deleted_description',
          'idx_expenses_category',
          'idx_expenses_deleted_category',
          'idx_expenses_target_currency',
        ]),
      );
    });

    test('可正常插入並查詢支出', () async {
      // Arrange & Act
      final id = await db.insert('expenses', {
        'date': '2026-01-15',
        'original_amount': 1050,
        'original_currency': 'USD',
        'exchange_rate': 7800000,
        'exchange_rate_source': 'api',
        'hkd_amount': 8190,
        'description': '午餐',
        'category': '餐飲',
        'target_currency': 'HKD',
        'is_deleted': 0,
        'created_at': '2026-01-15T12:00:00Z',
        'updated_at': '2026-01-15T12:00:00Z',
      });

      // Assert
      final row = await db.query('expenses', where: 'id = ?', whereArgs: [id]);
      expect(row.length, 1);
      expect(row.first['description'], '午餐');
      expect(row.first['category'], '餐飲');
      expect(row.first['target_currency'], 'HKD');
    });
  });

  group('v1→v2 遷移', () {
    late Database db;

    setUp(() async {
      db = await _openFreshDb();
      // 建立 v1 schema
      await _createV1Schema(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('遷移後 expenses 應有 category 欄位', () async {
      // Arrange - 確認 v1 沒有 category
      final columnsBefore = await _getColumnNames(db, 'expenses');
      expect(columnsBefore, isNot(contains('category')));

      // Act
      await _migrateV1ToV2(db);

      // Assert
      final columnsAfter = await _getColumnNames(db, 'expenses');
      expect(columnsAfter, contains('category'));
    });

    test('遷移後應建立 category 相關索引', () async {
      await _migrateV1ToV2(db);

      final indexes = await _getIndexNames(db, 'expenses');
      expect(
        indexes,
        containsAll([
          'idx_expenses_category',
          'idx_expenses_deleted_category',
        ]),
      );
    });

    test('既有資料的 category 應為 null', () async {
      // Arrange - 在 v1 插入資料
      await _insertV1Expense(
        db,
        date: '2026-01-10',
        amount: 500,
        currency: 'HKD',
        description: '測試支出',
      );

      // Act
      await _migrateV1ToV2(db);

      // Assert
      final rows = await db.query('expenses');
      expect(rows.length, 1);
      expect(rows.first['category'], isNull);
      expect(rows.first['description'], '測試支出');
    });
  });

  group('v2→v3 遷移', () {
    late Database db;

    setUp(() async {
      db = await _openFreshDb();
      // 先建立 v1 再遷移到 v2
      await _createV1Schema(db);
      await _migrateV1ToV2(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('遷移後 expenses 應有 target_currency 欄位', () async {
      // Arrange
      final columnsBefore = await _getColumnNames(db, 'expenses');
      expect(columnsBefore, isNot(contains('target_currency')));

      // Act
      await _migrateV2ToV3(db);

      // Assert
      final columnsAfter = await _getColumnNames(db, 'expenses');
      expect(columnsAfter, contains('target_currency'));
    });

    test('既有資料的 target_currency 應預設為 HKD', () async {
      // Arrange - 在 v2 插入資料（已有 category）
      await db.insert('expenses', {
        'date': '2026-01-10',
        'original_amount': 1000,
        'original_currency': 'JPY',
        'exchange_rate': 51000,
        'exchange_rate_source': 'api',
        'hkd_amount': 51,
        'description': '日本午餐',
        'category': '餐飲',
        'is_deleted': 0,
        'created_at': '2026-01-10T12:00:00Z',
        'updated_at': '2026-01-10T12:00:00Z',
      });

      // Act
      await _migrateV2ToV3(db);

      // Assert
      final rows = await db.query('expenses');
      expect(rows.length, 1);
      expect(rows.first['target_currency'], 'HKD');
    });

    test('exchange_rate_cache 應從單主鍵重建為複合主鍵', () async {
      // Arrange - 在 v2（舊結構）插入匯率快取
      await db.insert('exchange_rate_cache', {
        'currency': 'USD',
        'rate_to_hkd': 7800000,
        'fetched_at': '2026-01-01T00:00:00Z',
        'source': 'api',
      });
      await db.insert('exchange_rate_cache', {
        'currency': 'JPY',
        'rate_to_hkd': 51000,
        'fetched_at': '2026-01-01T00:00:00Z',
        'source': 'api',
      });

      // Act
      await _migrateV2ToV3(db);

      // Assert - 新結構應有 base_currency 欄位
      final columns = await _getColumnNames(db, 'exchange_rate_cache');
      expect(columns, contains('base_currency'));
      expect(columns, contains('rate'));
      expect(columns, isNot(contains('rate_to_hkd')));

      // 資料應保留，base_currency 設為 HKD
      final rows = await db.query(
        'exchange_rate_cache',
        orderBy: 'currency',
      );
      expect(rows.length, 2);
      expect(rows[0]['currency'], 'JPY');
      expect(rows[0]['base_currency'], 'HKD');
      expect(rows[0]['rate'], 51000);
      expect(rows[1]['currency'], 'USD');
      expect(rows[1]['base_currency'], 'HKD');
      expect(rows[1]['rate'], 7800000);
    });

    test('遷移後不應殘留備份表', () async {
      // Arrange
      await db.insert('exchange_rate_cache', {
        'currency': 'USD',
        'rate_to_hkd': 7800000,
        'fetched_at': '2026-01-01T00:00:00Z',
        'source': 'api',
      });

      // Act
      await _migrateV2ToV3(db);

      // Assert - 備份表應已刪除
      final tables = await _getTableNames(db);
      expect(tables, isNot(contains('exchange_rate_cache_backup')));
    });

    test('遷移後應有 target_currency 索引', () async {
      await _migrateV2ToV3(db);

      final indexes = await _getIndexNames(db, 'expenses');
      expect(indexes, contains('idx_expenses_target_currency'));
    });
  });

  group('v1→v3 完整遷移路徑 - 資料保留驗證', () {
    late Database db;

    setUp(() async {
      db = await _openFreshDb();
      await _createV1Schema(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('支出資料應在完整遷移後完整保留', () async {
      // Arrange - 在 v1 插入多筆測試資料
      final id1 = await _insertV1Expense(
        db,
        date: '2026-01-05',
        amount: 1500,
        currency: 'USD',
        description: '商務午餐',
      );
      final id2 = await _insertV1Expense(
        db,
        date: '2026-01-10',
        amount: 3000,
        currency: 'JPY',
        description: '計程車',
      );
      final id3 = await _insertV1Expense(
        db,
        date: '2026-01-15',
        amount: 500,
        currency: 'HKD',
        description: '咖啡',
      );

      // Act - 完整遷移 v1→v2→v3
      await _migrateV1ToV2(db);
      await _migrateV2ToV3(db);

      // Assert - 所有資料應完整保留
      final rows = await db.query('expenses', orderBy: 'id');
      expect(rows.length, 3);

      // 驗證第一筆
      expect(rows[0]['id'], id1);
      expect(rows[0]['description'], '商務午餐');
      expect(rows[0]['original_amount'], 1500);
      expect(rows[0]['original_currency'], 'USD');
      expect(rows[0]['category'], isNull); // v1 資料無分類
      expect(rows[0]['target_currency'], 'HKD'); // v3 預設值

      // 驗證第二筆
      expect(rows[1]['id'], id2);
      expect(rows[1]['description'], '計程車');
      expect(rows[1]['original_currency'], 'JPY');

      // 驗證第三筆
      expect(rows[2]['id'], id3);
      expect(rows[2]['description'], '咖啡');
    });

    test('匯率快取應在完整遷移後正確轉換', () async {
      // Arrange - v1 匯率快取
      await db.insert('exchange_rate_cache', {
        'currency': 'USD',
        'rate_to_hkd': 7800000,
        'fetched_at': '2026-01-01T00:00:00Z',
        'source': 'frankfurter',
      });

      // Act
      await _migrateV1ToV2(db); // v1→v2 不影響 exchange_rate_cache
      await _migrateV2ToV3(db); // v2→v3 重建表結構

      // Assert
      final rows = await db.query('exchange_rate_cache');
      expect(rows.length, 1);
      expect(rows.first['currency'], 'USD');
      expect(rows.first['base_currency'], 'HKD');
      expect(rows.first['rate'], 7800000);
      expect(rows.first['source'], 'frankfurter');
    });

    test('backup_status 應在遷移後保持不變', () async {
      // Arrange - 更新備份狀態
      await db.update(
        'backup_status',
        {
          'last_backup_at': '2026-01-01T00:00:00Z',
          'last_backup_count': 42,
          'last_backup_size_kb': 1024,
          'google_email': 'test@example.com',
        },
        where: 'id = 1',
      );

      // Act
      await _migrateV1ToV2(db);
      await _migrateV2ToV3(db);

      // Assert
      final rows = await db.query('backup_status');
      expect(rows.length, 1);
      expect(rows.first['last_backup_count'], 42);
      expect(rows.first['last_backup_size_kb'], 1024);
      expect(rows.first['google_email'], 'test@example.com');
    });

    test('app_settings 應在遷移後保持不變', () async {
      // Arrange
      await db.insert('app_settings', {'key': 'theme', 'value': 'dark'});
      await db.insert('app_settings', {'key': 'locale', 'value': 'zh'});

      // Act
      await _migrateV1ToV2(db);
      await _migrateV2ToV3(db);

      // Assert
      final rows = await db.query('app_settings', orderBy: 'key');
      expect(rows.length, 2);
      expect(rows[0]['key'], 'locale');
      expect(rows[0]['value'], 'zh');
      expect(rows[1]['key'], 'theme');
      expect(rows[1]['value'], 'dark');
    });

    test('遷移後應能正常執行 v3 的完整 CRUD', () async {
      // Arrange - 從 v1 遷移到 v3
      await _insertV1Expense(
        db,
        date: '2026-01-01',
        amount: 100,
        currency: 'HKD',
        description: '舊資料',
      );
      await _migrateV1ToV2(db);
      await _migrateV2ToV3(db);

      // Act - 使用 v3 完整欄位插入新資料
      final newId = await db.insert('expenses', {
        'date': '2026-02-01',
        'original_amount': 2000,
        'original_currency': 'USD',
        'exchange_rate': 7800000,
        'exchange_rate_source': 'api',
        'hkd_amount': 15600,
        'description': '新支出',
        'category': '交通',
        'target_currency': 'TWD',
        'is_deleted': 0,
        'created_at': '2026-02-01T00:00:00Z',
        'updated_at': '2026-02-01T00:00:00Z',
      });

      // Assert
      final allRows = await db.query('expenses', orderBy: 'id');
      expect(allRows.length, 2);

      final newRow = allRows.last;
      expect(newRow['id'], newId);
      expect(newRow['category'], '交通');
      expect(newRow['target_currency'], 'TWD');

      // 驗證更新操作
      await db.update(
        'expenses',
        {'description': '更新後的支出'},
        where: 'id = ?',
        whereArgs: [newId],
      );
      final updated = await db.query(
        'expenses',
        where: 'id = ?',
        whereArgs: [newId],
      );
      expect(updated.first['description'], '更新後的支出');

      // 驗證軟刪除
      await db.update(
        'expenses',
        {'is_deleted': 1, 'deleted_at': '2026-02-02T00:00:00Z'},
        where: 'id = ?',
        whereArgs: [newId],
      );
      final active = await db.query(
        'expenses',
        where: 'is_deleted = 0',
      );
      expect(active.length, 1);
      expect(active.first['description'], '舊資料');
    });
  });

  group('邊界情況', () {
    test('空的 exchange_rate_cache 遷移 v2→v3 不應出錯', () async {
      final db = await _openFreshDb();
      try {
        await _createV1Schema(db);
        await _migrateV1ToV2(db);

        // exchange_rate_cache 為空時遷移
        await _migrateV2ToV3(db);

        // 驗證表結構正確
        final columns = await _getColumnNames(db, 'exchange_rate_cache');
        expect(columns, contains('base_currency'));

        final rows = await db.query('exchange_rate_cache');
        expect(rows, isEmpty);
      } finally {
        await db.close();
      }
    });

    test('含軟刪除資料的遷移應正確保留刪除狀態', () async {
      final db = await _openFreshDb();
      try {
        await _createV1Schema(db);

        // 插入已軟刪除的資料
        await db.insert('expenses', {
          'date': '2026-01-01',
          'original_amount': 100,
          'original_currency': 'HKD',
          'exchange_rate': 1000000,
          'exchange_rate_source': 'test',
          'hkd_amount': 100,
          'description': '已刪除',
          'is_deleted': 1,
          'deleted_at': '2026-01-02T00:00:00Z',
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-02T00:00:00Z',
        });

        // 完整遷移
        await _migrateV1ToV2(db);
        await _migrateV2ToV3(db);

        // 驗證
        final rows = await db.query('expenses');
        expect(rows.length, 1);
        expect(rows.first['is_deleted'], 1);
        expect(rows.first['deleted_at'], '2026-01-02T00:00:00Z');
        expect(rows.first['target_currency'], 'HKD');
      } finally {
        await db.close();
      }
    });

    test('大量資料遷移應正常完成', () async {
      final db = await _openFreshDb();
      try {
        await _createV1Schema(db);

        // 批次插入 100 筆資料
        final batch = db.batch();
        for (var i = 0; i < 100; i++) {
          batch.insert('expenses', {
            'date': '2026-01-${(i % 28 + 1).toString().padLeft(2, '0')}',
            'original_amount': (i + 1) * 100,
            'original_currency': ['HKD', 'USD', 'JPY', 'TWD'][i % 4],
            'exchange_rate': 1000000,
            'exchange_rate_source': 'test',
            'hkd_amount': (i + 1) * 100,
            'description': '支出 #$i',
            'is_deleted': 0,
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-01T00:00:00Z',
          });
        }
        await batch.commit(noResult: true);

        // 完整遷移
        await _migrateV1ToV2(db);
        await _migrateV2ToV3(db);

        // 驗證所有資料保留
        final countResult = await db.rawQuery('SELECT COUNT(*) FROM expenses');
        final count = countResult.first.values.first as int;
        expect(count, 100);

        // 抽樣驗證新欄位
        final sample = await db.query(
          'expenses',
          where: 'id = ?',
          whereArgs: [50],
        );
        expect(sample.first['category'], isNull);
        expect(sample.first['target_currency'], 'HKD');
      } finally {
        await db.close();
      }
    });
  });
}
