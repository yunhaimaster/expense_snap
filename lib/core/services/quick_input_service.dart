import '../../data/datasources/local/database_helper.dart';

/// 快捷輸入服務
///
/// 管理常用描述和最近使用的輸入
class QuickInputService {
  QuickInputService._();

  static final instance = QuickInputService._();

  final _db = DatabaseHelper.instance;

  /// 最大儲存描述數量
  static const int maxRecentDescriptions = 10;

  /// 轉義 LIKE 模式中的特殊字元
  ///
  /// 防止 % 和 _ 被解釋為萬用字元
  String _escapeLikePattern(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
  }

  /// 取得最近使用的描述（用於自動完成）
  Future<List<String>> getRecentDescriptions() async {
    final db = await _db.database;

    // 從 expenses 表取得最近使用的不重複描述
    final result = await db.rawQuery('''
      SELECT DISTINCT description
      FROM expenses
      WHERE deleted_at IS NULL AND description IS NOT NULL AND description != ''
      ORDER BY created_at DESC
      LIMIT ?
    ''', [maxRecentDescriptions]);

    return result
        .map((row) => row['description'] as String?)
        .where((desc) => desc != null && desc.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// 搜尋符合的描述
  Future<List<String>> searchDescriptions(String query) async {
    if (query.isEmpty) return [];

    final db = await _db.database;

    // 轉義特殊字元，防止 LIKE pattern injection
    final escapedQuery = _escapeLikePattern(query);

    // 搜尋包含查詢字串的描述
    final result = await db.rawQuery('''
      SELECT DISTINCT description
      FROM expenses
      WHERE deleted_at IS NULL
        AND description IS NOT NULL
        AND description LIKE ? ESCAPE '\\'
      ORDER BY created_at DESC
      LIMIT ?
    ''', ['%$escapedQuery%', maxRecentDescriptions]);

    return result
        .map((row) => row['description'] as String?)
        .where((desc) => desc != null && desc.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// 取得最近使用的幣種（按使用頻率排序）
  Future<List<String>> getRecentCurrencies() async {
    final db = await _db.database;

    // 按使用頻率排序幣種
    final result = await db.rawQuery('''
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

  /// 取得常用金額（用於快速輸入）
  Future<List<int>> getCommonAmounts() async {
    final db = await _db.database;

    // 取得最常用的金額（以分為單位）
    final result = await db.rawQuery('''
      SELECT hkd_amount_cents, COUNT(*) as count
      FROM expenses
      WHERE deleted_at IS NULL AND hkd_amount_cents IS NOT NULL
      GROUP BY hkd_amount_cents
      ORDER BY count DESC
      LIMIT 5
    ''');

    return result
        .map((row) => row['hkd_amount_cents'] as int?)
        .where((amount) => amount != null)
        .cast<int>()
        .toList();
  }
}
