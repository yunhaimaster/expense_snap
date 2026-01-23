import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

import '../../../core/utils/app_logger.dart';

/// 資料庫助手 - 單例模式管理 SQLite 連線
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _databaseName = 'expense_snap.db';
  static const int _databaseVersion = 3; // v2→v3: 新增 target_currency 欄位

  /// 匯率快取最大條目數
  static const int maxCacheEntries = 50;

  Database? _database;
  // 使用 Lock 確保並發初始化時的線程安全
  final Lock _initLock = Lock();

  /// 取得資料庫實例（使用 Lock 確保線程安全）
  ///
  /// 使用 synchronized 套件的 Lock，確保並發呼叫時只初始化一次
  Future<Database> get database async {
    // 快速路徑：如果已初始化，直接返回
    if (_database != null) return _database!;

    // 使用 Lock 確保初始化只執行一次
    return _initLock.synchronized(() async {
      // 再次檢查（雙重檢查鎖定模式）
      if (_database != null) return _database!;

      _database = await _initDatabase();
      return _database!;
    });
  }

  /// 初始化資料庫
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    AppLogger.database('Opening database at $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// 設定資料庫（啟用 WAL mode 和外鍵約束）
  Future<void> _onConfigure(Database db) async {
    // 啟用 WAL mode 提升並發性能（使用 rawQuery 因為 PRAGMA 會返回結果）
    final walResult = await db.rawQuery('PRAGMA journal_mode=WAL');
    final journalMode = walResult.isNotEmpty
        ? walResult.first['journal_mode'] as String?
        : null;
    if (journalMode != 'wal') {
      AppLogger.warning('WAL mode not enabled, got: $journalMode');
    }

    // 啟用外鍵約束
    await db.rawQuery('PRAGMA foreign_keys=ON');
    final fkResult = await db.rawQuery('PRAGMA foreign_keys');
    final fkEnabled = fkResult.isNotEmpty
        ? fkResult.first['foreign_keys'] as int?
        : null;
    if (fkEnabled != 1) {
      AppLogger.warning('Foreign keys not enabled, got: $fkEnabled');
    }

    AppLogger.database('Database configured with WAL mode');
  }

  /// 建立資料表
  Future<void> _onCreate(Database db, int version) async {
    AppLogger.database('Creating database tables (version $version)');

    // 建立 expenses 表（含 category 和 target_currency 欄位）
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

    // 建立 expenses 索引
    await db.execute('''
      CREATE INDEX idx_expenses_date ON expenses (date)
    ''');
    await db.execute('''
      CREATE INDEX idx_expenses_is_deleted ON expenses (is_deleted)
    ''');
    await db.execute('''
      CREATE INDEX idx_expenses_deleted_at ON expenses (deleted_at)
    ''');
    // 複合索引：優化常見查詢（軟刪除篩選 + 建立時間排序）
    await db.execute('''
      CREATE INDEX idx_expenses_deleted_created ON expenses (is_deleted, created_at DESC)
    ''');
    // 複合索引：優化描述自動完成查詢
    await db.execute('''
      CREATE INDEX idx_expenses_deleted_description ON expenses (is_deleted, description)
    ''');
    // 分類索引：支援未來按分類篩選
    await db.execute('''
      CREATE INDEX idx_expenses_category ON expenses (category)
    ''');
    // 複合索引：優化常見查詢（軟刪除篩選 + 分類）
    await db.execute('''
      CREATE INDEX idx_expenses_deleted_category ON expenses (is_deleted, category)
    ''');
    // 目標幣種索引：支援多幣種查詢
    await db.execute('''
      CREATE INDEX idx_expenses_target_currency ON expenses (target_currency)
    ''');

    // 建立 exchange_rate_cache 表（複合主鍵：currency + base_currency）
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

    // 建立 backup_status 表（單行記錄）
    await db.execute('''
      CREATE TABLE backup_status (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        last_backup_at TEXT,
        last_backup_count INTEGER NOT NULL DEFAULT 0,
        last_backup_size_kb INTEGER NOT NULL DEFAULT 0,
        google_email TEXT
      )
    ''');

    // 初始化 backup_status 單行記錄
    await db.insert('backup_status', {
      'id': 1,
      'last_backup_count': 0,
      'last_backup_size_kb': 0,
    });

    // 建立 app_settings 表（key-value 儲存）
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    AppLogger.database('Database tables created successfully');
  }

  /// 升級資料庫
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.database('Upgrading database from v$oldVersion to v$newVersion');

    // v1 → v2: 新增 category 欄位和索引
    if (oldVersion < 2) {
      AppLogger.database('Migration v1→v2: Adding category column');

      // 新增 category 欄位（nullable，無需遷移現有資料）
      await db.execute('ALTER TABLE expenses ADD COLUMN category TEXT');

      // 新增分類索引（使用 IF NOT EXISTS 提高容錯性）
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses (category)
      ''');

      // 新增複合索引（軟刪除 + 分類）
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_expenses_deleted_category ON expenses (is_deleted, category)
      ''');

      // 執行 ANALYZE 更新統計資訊，優化查詢計劃
      await db.execute('ANALYZE');

      AppLogger.database(
        'Migration v1→v2 completed in ${stopwatch.elapsedMilliseconds}ms',
      );
    }

    // v2 → v3: 新增 target_currency 欄位，更新 exchange_rate_cache 結構
    if (oldVersion < 3) {
      AppLogger.database('Migration v2→v3: Adding target_currency column');

      // 使用 transaction 確保原子性
      await db.transaction((txn) async {
        // 1. 新增 target_currency 欄位（預設 HKD）
        await txn.execute(
          "ALTER TABLE expenses ADD COLUMN target_currency TEXT NOT NULL DEFAULT 'HKD'",
        );

        // 2. 新增索引
        await txn.execute('''
          CREATE INDEX IF NOT EXISTS idx_expenses_target_currency ON expenses (target_currency)
        ''');

        // 3. 重建 exchange_rate_cache 表（複合主鍵）
        // 3a. 備份舊資料
        await txn.execute('''
          CREATE TABLE exchange_rate_cache_backup AS
          SELECT currency, rate_to_hkd as rate, fetched_at, source
          FROM exchange_rate_cache
        ''');

        // 3b. 刪除舊表
        await txn.execute('DROP TABLE exchange_rate_cache');

        // 3c. 建立新表（複合主鍵）
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

        // 3d. 恢復資料（舊資料都是 HKD 為基準）
        // 使用 COALESCE 處理可能的 NULL rate，過濾無效資料
        await txn.execute('''
          INSERT INTO exchange_rate_cache (currency, base_currency, rate, fetched_at, source)
          SELECT currency, 'HKD', COALESCE(rate, 0), fetched_at, source
          FROM exchange_rate_cache_backup
          WHERE rate IS NOT NULL
        ''');

        // 3e. 刪除備份表
        await txn.execute('DROP TABLE exchange_rate_cache_backup');
      });

      await db.execute('ANALYZE');

      AppLogger.database(
        'Migration v2→v3 completed in ${stopwatch.elapsedMilliseconds}ms',
      );
    }

    stopwatch.stop();
  }

  /// 關閉資料庫
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      AppLogger.database('Database closed');
    }
  }

  /// 取得資料庫路徑（用於備份）
  Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, _databaseName);
  }

  // ============ Expenses CRUD ============

  /// 插入支出
  Future<int> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    final id = await db.insert('expenses', expense);
    AppLogger.database('Insert expense', table: 'expenses', affectedRows: 1);
    return id;
  }

  /// 更新支出
  Future<int> updateExpense(int id, Map<String, dynamic> expense) async {
    final db = await database;
    final rows = await db.update(
      'expenses',
      expense,
      where: 'id = ?',
      whereArgs: [id],
    );
    AppLogger.database('Update expense', table: 'expenses', affectedRows: rows);
    return rows;
  }

  /// 查詢月份支出列表
  Future<List<Map<String, dynamic>>> getExpensesByMonth({
    required int year,
    required int month,
    required bool includeDeleted,
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    // 使用年月前綴匹配，避免時區差異問題
    final monthStr = month.toString().padLeft(2, '0');
    final yearMonthPrefix = '$year-$monthStr';

    final where = includeDeleted
        ? 'substr(date, 1, 7) = ?'
        : 'substr(date, 1, 7) = ? AND is_deleted = 0';

    final results = await db.query(
      'expenses',
      where: where,
      whereArgs: [yearMonthPrefix],
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );

    AppLogger.database(
      'Query expenses by month ($year-$month)',
      table: 'expenses',
      affectedRows: results.length,
    );

    return results;
  }

  /// 查詢月份支出數量（用於串流匯出判斷）
  Future<int> getExpenseCountByMonth({
    required int year,
    required int month,
  }) async {
    final db = await database;

    final monthStr = month.toString().padLeft(2, '0');
    final yearMonthPrefix = '$year-$monthStr';

    final results = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM expenses
      WHERE substr(date, 1, 7) = ? AND is_deleted = 0
    ''',
      [yearMonthPrefix],
    );

    return results.first['count'] as int;
  }

  /// 查詢單筆支出
  Future<Map<String, dynamic>?> getExpenseById(int id) async {
    final db = await database;
    final results = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// 查詢已刪除支出
  Future<List<Map<String, dynamic>>> getDeletedExpenses() async {
    final db = await database;
    final results = await db.query(
      'expenses',
      where: 'is_deleted = 1',
      orderBy: 'deleted_at DESC',
    );
    AppLogger.database(
      'Query deleted expenses',
      table: 'expenses',
      affectedRows: results.length,
    );
    return results;
  }

  /// 查詢待清理的過期刪除支出
  Future<List<Map<String, dynamic>>> getExpiredDeletedExpenses(
    int retentionDays,
  ) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

    final results = await db.query(
      'expenses',
      where: 'is_deleted = 1 AND deleted_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );

    AppLogger.database(
      'Query expired deleted expenses',
      table: 'expenses',
      affectedRows: results.length,
    );

    return results;
  }

  /// 永久刪除支出
  Future<int> deleteExpense(int id) async {
    final db = await database;
    final rows = await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    AppLogger.database('Delete expense', table: 'expenses', affectedRows: rows);
    return rows;
  }

  /// 查詢月份摘要（支援多幣種偵測）
  Future<Map<String, dynamic>> getMonthSummary(int year, int month) async {
    final db = await database;

    // 使用年月前綴匹配，避免時區差異問題
    final monthStr = month.toString().padLeft(2, '0');
    final yearMonthPrefix = '$year-$monthStr';

    final results = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as total_count,
        COALESCE(SUM(hkd_amount), 0) as total_hkd_amount,
        COUNT(DISTINCT target_currency) as currency_count,
        (
          SELECT target_currency
          FROM expenses
          WHERE substr(date, 1, 7) = ? AND is_deleted = 0
          GROUP BY target_currency
          ORDER BY COUNT(*) DESC
          LIMIT 1
        ) as dominant_currency
      FROM expenses
      WHERE substr(date, 1, 7) = ? AND is_deleted = 0
    ''',
      [yearMonthPrefix, yearMonthPrefix],
    );

    return results.first;
  }

  // ============ Exchange Rate Cache ============

  /// 取得快取匯率（支援指定基準幣種）
  Future<Map<String, dynamic>?> getExchangeRateCache(
    String currency, {
    String baseCurrency = 'HKD',
  }) async {
    final db = await database;
    final results = await db.query(
      'exchange_rate_cache',
      where: 'currency = ? AND base_currency = ?',
      whereArgs: [currency, baseCurrency],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// 儲存或更新快取匯率（支援指定基準幣種）
  Future<void> upsertExchangeRateCache(Map<String, dynamic> cache) async {
    final db = await database;
    await db.insert(
      'exchange_rate_cache',
      cache,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppLogger.database(
      'Upsert exchange rate cache',
      table: 'exchange_rate_cache',
    );

    // 清理超過限制的舊快取
    await _cleanupOldCache(db);
  }

  /// 清理超過限制的舊快取
  Future<void> _cleanupOldCache(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM exchange_rate_cache'),
    );

    if (count != null && count > maxCacheEntries) {
      final deleted = await db.rawDelete('''
        DELETE FROM exchange_rate_cache
        WHERE rowid NOT IN (
          SELECT rowid FROM exchange_rate_cache
          ORDER BY fetched_at DESC LIMIT $maxCacheEntries
        )
      ''');
      AppLogger.database(
        'Cleaned up exchange rate cache',
        table: 'exchange_rate_cache',
        affectedRows: deleted,
      );
    }
  }

  /// 清除匯率快取（用於強制刷新）
  Future<void> clearExchangeRateCache({String? baseCurrency}) async {
    final db = await database;
    if (baseCurrency != null) {
      await db.delete(
        'exchange_rate_cache',
        where: 'base_currency = ?',
        whereArgs: [baseCurrency],
      );
    } else {
      await db.delete('exchange_rate_cache');
    }
    AppLogger.database(
      'Cleared exchange rate cache',
      table: 'exchange_rate_cache',
    );
  }

  // ============ Backup Status ============

  /// 取得備份狀態
  Future<Map<String, dynamic>?> getBackupStatus() async {
    final db = await database;
    final results = await db.query(
      'backup_status',
      where: 'id = 1',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// 更新備份狀態
  Future<void> updateBackupStatus(Map<String, dynamic> status) async {
    final db = await database;
    await db.update(
      'backup_status',
      status,
      where: 'id = 1',
    );
    AppLogger.database('Update backup status', table: 'backup_status');
  }

  // ============ App Settings ============

  /// 取得設定值
  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return results.isNotEmpty ? results.first['value'] as String? : null;
  }

  /// 儲存設定值
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 取得所有設定
  Future<Map<String, String?>> getAllSettings() async {
    final db = await database;
    final results = await db.query('app_settings');

    final map = <String, String?>{};
    for (final row in results) {
      map[row['key'] as String] = row['value'] as String?;
    }
    return map;
  }

  /// 批量儲存設定
  Future<void> setSettings(Map<String, String> settings) async {
    final db = await database;
    final batch = db.batch();

    for (final entry in settings.entries) {
      batch.insert(
        'app_settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    AppLogger.database('Batch update settings', affectedRows: settings.length);
  }
}
