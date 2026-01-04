import '../../data/datasources/local/database_helper.dart';
import '../../data/models/expense.dart';

/// 智慧提示服務
///
/// 提供重複支出偵測和大金額確認等功能
class SmartPromptService {
  SmartPromptService._();

  static final instance = SmartPromptService._();

  final _db = DatabaseHelper.instance;

  /// 大金額門檻（以港幣分計）- 1000 HKD
  static const int largeAmountThreshold = 100000;

  /// 重複偵測時間窗口（小時）
  static const int duplicateWindowHours = 24;

  /// 檢查是否為大金額
  bool isLargeAmount(int hkdAmountCents) {
    return hkdAmountCents >= largeAmountThreshold;
  }

  /// 檢查是否有重複支出
  ///
  /// 條件：24 小時內相同金額且描述相似的支出
  Future<Expense?> findDuplicateExpense({
    required int hkdAmountCents,
    required String description,
    required DateTime date,
  }) async {
    final db = await _db.database;

    // 計算時間範圍
    final startTime = date.subtract(const Duration(hours: duplicateWindowHours));
    final endTime = date.add(const Duration(hours: duplicateWindowHours));

    // 查詢相同金額且時間接近的支出
    final result = await db.query(
      'expenses',
      where: '''
        deleted_at IS NULL
        AND hkd_amount_cents = ?
        AND date >= ?
        AND date <= ?
      ''',
      whereArgs: [
        hkdAmountCents,
        startTime.millisecondsSinceEpoch,
        endTime.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    final existingExpense = Expense.fromMap(result.first);

    // 檢查描述相似度
    if (_isSimilarDescription(description, existingExpense.description)) {
      return existingExpense;
    }

    return null;
  }

  /// 檢查描述是否相似
  bool _isSimilarDescription(String desc1, String desc2) {
    // 簡單相似度檢查：忽略空白後比較
    final normalized1 = desc1.trim().toLowerCase();
    final normalized2 = desc2.trim().toLowerCase();

    // 任一描述為空則不視為相似（避免誤判）
    if (normalized1.isEmpty || normalized2.isEmpty) {
      return false;
    }

    // 完全相同
    if (normalized1 == normalized2) return true;

    // 一個包含另一個（需要至少 2 字元才比較）
    if (normalized1.length >= 2 &&
        normalized2.length >= 2 &&
        (normalized1.contains(normalized2) ||
            normalized2.contains(normalized1))) {
      return true;
    }

    // 計算共同字數比例
    final words1 = normalized1.split(RegExp(r'\s+'));
    final words2 = normalized2.split(RegExp(r'\s+'));

    // 過濾空字串
    final validWords1 = words1.where((w) => w.isNotEmpty).toList();
    final validWords2 = words2.where((w) => w.isNotEmpty).toList();

    if (validWords1.isEmpty || validWords2.isEmpty) {
      return false;
    }

    final commonWords =
        validWords1.where(validWords2.contains).length;
    final maxWords =
        validWords1.length > validWords2.length ? validWords1.length : validWords2.length;

    // 超過 50% 共同字則視為相似
    return maxWords > 0 && commonWords / maxWords > 0.5;
  }

  /// 檢查當月是否接近月底（用於匯出提醒）
  bool isNearMonthEnd() {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = lastDayOfMonth - now.day;

    // 最後 3 天
    return daysRemaining <= 3;
  }

  /// 取得當月支出數量
  Future<int> getCurrentMonthExpenseCount() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM expenses
      WHERE deleted_at IS NULL
        AND date >= ?
        AND date <= ?
    ''', [
      startOfMonth.millisecondsSinceEpoch,
      endOfMonth.millisecondsSinceEpoch,
    ]);

    return (result.first['count'] as int?) ?? 0;
  }
}
