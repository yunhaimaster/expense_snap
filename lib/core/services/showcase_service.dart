import '../../data/datasources/local/database_helper.dart';

/// Showcase 提示服務
///
/// 管理功能發現提示的狀態與持久化
class ShowcaseService {
  ShowcaseService._();

  static final instance = ShowcaseService._();

  // Showcase 鍵值
  static const String fabShowcase = 'showcase_fab';
  static const String swipeDeleteShowcase = 'showcase_swipe_delete';
  static const String exportShowcase = 'showcase_export';

  final _db = DatabaseHelper.instance;

  /// 檢查 showcase 是否已完成
  Future<bool> isShowcaseComplete(String key) async {
    final value = await _db.getSetting(key);
    return value == 'true';
  }

  /// 標記 showcase 已完成
  Future<void> markShowcaseComplete(String key) async {
    await _db.setSetting(key, 'true');
  }

  /// 重置所有 showcase（開發用）
  Future<void> resetAllShowcases() async {
    await _db.setSetting(fabShowcase, 'false');
    await _db.setSetting(swipeDeleteShowcase, 'false');
    await _db.setSetting(exportShowcase, 'false');
  }

  /// 取得使用者的支出數量（用於判斷是否顯示匯出提示）
  Future<int> getExpenseCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM expenses WHERE deleted_at IS NULL',
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
