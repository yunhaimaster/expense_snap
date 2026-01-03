import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/utils/app_logger.dart';

/// 資料庫助手 - 單例模式管理 SQLite 連線
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _databaseName = 'expense_snap.db';
  static const int _databaseVersion = 1;

  Database? _database;
  Completer<Database>? _initCompleter;

  /// 取得資料庫實例（使用 Completer 確保線程安全）
  Future<Database> get database async {
    // 如果已初始化，直接返回
    if (_database != null) return _database!;

    // 如果正在初始化中，等待完成
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    // 開始初始化
    _initCompleter = Completer<Database>();

    try {
      _database = await _initDatabase();
      _initCompleter!.complete(_database!);
      return _database!;
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null; // 重置以便重試
      rethrow;
    }
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
    // 啟用 WAL mode 提升並發性能
    await db.execute('PRAGMA journal_mode=WAL');
    // 啟用外鍵約束
    await db.execute('PRAGMA foreign_keys=ON');

    AppLogger.database('Database configured with WAL mode');
  }

  /// 建立資料表
  Future<void> _onCreate(Database db, int version) async {
    AppLogger.database('Creating database tables (version $version)');

    // 建立 expenses 表
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

    // 建立 exchange_rate_cache 表
    await db.execute('''
      CREATE TABLE exchange_rate_cache (
        currency TEXT PRIMARY KEY,
        rate_to_hkd INTEGER NOT NULL,
        fetched_at TEXT NOT NULL,
        source TEXT NOT NULL
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
    AppLogger.database('Upgrading database from v$oldVersion to v$newVersion');

    // 未來版本升級邏輯
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE expenses ADD COLUMN category TEXT');
    // }
  }

  /// 關閉資料庫
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _initCompleter = null; // 重置 completer 以便重新初始化
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

    // 計算月份起訖日期
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final where = includeDeleted
        ? 'date BETWEEN ? AND ?'
        : 'date BETWEEN ? AND ? AND is_deleted = 0';

    final results = await db.query(
      'expenses',
      where: where,
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
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
  Future<List<Map<String, dynamic>>> getExpiredDeletedExpenses(int retentionDays) async {
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

  /// 查詢月份摘要
  Future<Map<String, dynamic>> getMonthSummary(int year, int month) async {
    final db = await database;

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final results = await db.rawQuery('''
      SELECT
        COUNT(*) as total_count,
        COALESCE(SUM(hkd_amount), 0) as total_hkd_amount
      FROM expenses
      WHERE date BETWEEN ? AND ? AND is_deleted = 0
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return results.first;
  }

  // ============ Exchange Rate Cache ============

  /// 取得快取匯率
  Future<Map<String, dynamic>?> getExchangeRateCache(String currency) async {
    final db = await database;
    final results = await db.query(
      'exchange_rate_cache',
      where: 'currency = ?',
      whereArgs: [currency],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// 儲存或更新快取匯率
  Future<void> upsertExchangeRateCache(Map<String, dynamic> cache) async {
    final db = await database;
    await db.insert(
      'exchange_rate_cache',
      cache,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppLogger.database('Upsert exchange rate cache', table: 'exchange_rate_cache');
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
