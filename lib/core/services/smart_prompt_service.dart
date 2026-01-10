import '../../data/datasources/local/database_helper.dart';
import '../../data/models/expense.dart';
import '../constants/app_constants.dart';
import '../utils/string_utils.dart';

/// 智慧提示服務
///
/// 提供重複支出偵測和大金額確認等功能
class SmartPromptService {
  SmartPromptService._();

  static final instance = SmartPromptService._();

  final _db = DatabaseHelper.instance;

  /// 大金額門檻（以港幣分計）- 使用集中管理的常數
  static const int largeAmountThreshold = AppConstants.largeAmountThresholdCents;

  /// 重複偵測時間窗口（小時）- 延長至 48 小時以涵蓋隔天同筆支出
  static const int duplicateWindowHours = 48;

  /// 描述相似度門檻（0.0-1.0），使用 Levenshtein 編輯距離
  static const double similarityThreshold = 0.6;

  /// 檢查是否為大金額
  bool isLargeAmount(int hkdAmountCents) {
    return hkdAmountCents >= largeAmountThreshold;
  }

  /// 檢查是否有重複支出
  ///
  /// 條件：過去 48 小時內相同金額且描述相似的支出
  /// 使用 Levenshtein 編輯距離計算描述相似度
  /// 注意：只檢查過去的支出，避免與未來日期的支出誤匹配
  Future<Expense?> findDuplicateExpense({
    required int hkdAmountCents,
    required String description,
    required DateTime date,
  }) async {
    final db = await _db.database;

    // 計算時間範圍（只往前看，不檢查未來的支出）
    final startTime =
        date.subtract(const Duration(hours: duplicateWindowHours));
    final endTime = date; // 只檢查到當前日期，不包含未來

    // 查詢相同金額且時間接近的支出
    final result = await db.query(
      'expenses',
      where: '''
        deleted_at IS NULL
        AND hkd_amount = ?
        AND date >= ?
        AND date <= ?
      ''',
      whereArgs: [
        hkdAmountCents,
        startTime.toIso8601String(),
        endTime.toIso8601String(),
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
  ///
  /// 使用 Levenshtein 編輯距離計算相似度，
  /// 同時保留原有的包含檢查和共同字數檢查作為快速路徑
  bool _isSimilarDescription(String desc1, String desc2) {
    final normalized1 = StringUtils.normalize(desc1);
    final normalized2 = StringUtils.normalize(desc2);

    // 任一描述為空則不視為相似（避免誤判）
    if (normalized1.isEmpty || normalized2.isEmpty) {
      return false;
    }

    // 快速路徑：完全相同
    if (normalized1 == normalized2) return true;

    // 快速路徑：一個包含另一個（需要至少 2 字元才比較）
    if (normalized1.length >= 2 &&
        normalized2.length >= 2 &&
        (normalized1.contains(normalized2) ||
            normalized2.contains(normalized1))) {
      return true;
    }

    // 使用 Levenshtein 編輯距離計算相似度
    final similarity = StringUtils.similarityRatio(normalized1, normalized2);
    if (similarity >= similarityThreshold) {
      return true;
    }

    // 備用：計算共同字數比例（適用於多字詞描述）
    final words1 = normalized1.split(RegExp(r'\s+'));
    final words2 = normalized2.split(RegExp(r'\s+'));

    final validWords1 = words1.where((w) => w.isNotEmpty).toList();
    final validWords2 = words2.where((w) => w.isNotEmpty).toList();

    if (validWords1.isEmpty || validWords2.isEmpty) {
      return false;
    }

    final commonWords = validWords1.where(validWords2.contains).length;
    final maxWords = validWords1.length > validWords2.length
        ? validWords1.length
        : validWords2.length;

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
    // 使用年月前綴匹配，避免時區差異問題
    final monthStr = now.month.toString().padLeft(2, '0');
    final yearMonthPrefix = '${now.year}-$monthStr';

    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM expenses
      WHERE deleted_at IS NULL
        AND substr(date, 1, 7) = ?
    ''', [yearMonthPrefix]);

    return (result.first['count'] as int?) ?? 0;
  }
}
