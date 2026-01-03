import '../../core/errors/result.dart';
import '../../data/models/expense.dart';

/// 支出 Repository 抽象介面
///
/// 定義支出資料存取的標準介面，供依賴注入使用
abstract class IExpenseRepository {
  /// 新增支出
  ///
  /// [expense] - 支出資料（不含 id）
  /// [imagePath] - 原始圖片路徑（將被處理和儲存）
  Future<Result<Expense>> addExpense({
    required Expense expense,
    String? imagePath,
  });

  /// 更新支出
  Future<Result<Expense>> updateExpense(Expense expense);

  /// 取得單筆支出
  Future<Result<Expense>> getExpenseById(int id);

  /// 取得月份支出列表
  Future<Result<List<Expense>>> getExpensesByMonth({
    required int year,
    required int month,
    int? limit,
    int? offset,
  });

  /// 取得月份摘要
  Future<Result<MonthSummary>> getMonthSummary({
    required int year,
    required int month,
  });

  /// 軟刪除支出
  Future<Result<void>> softDeleteExpense(int id);

  /// 還原已刪除支出
  Future<Result<void>> restoreExpense(int id);

  /// 取得所有已刪除支出
  Future<Result<List<Expense>>> getDeletedExpenses();

  /// 永久刪除支出（包含圖片）
  Future<Result<void>> permanentlyDeleteExpense(int id);

  /// 清理過期的已刪除支出（30 天後）
  Future<Result<int>> cleanupExpiredDeletedExpenses();

  /// 替換收據圖片
  Future<Result<Expense>> replaceReceiptImage({
    required int expenseId,
    required String newImagePath,
  });
}
