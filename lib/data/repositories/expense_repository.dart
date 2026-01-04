import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../services/image_service.dart';
import '../datasources/local/database_helper.dart';
import '../models/expense.dart';

/// 支出 Repository 實作
///
/// 負責：
/// - 支出 CRUD 操作
/// - 圖片處理整合
/// - 軟刪除與還原
/// - 過期清理
class ExpenseRepository implements IExpenseRepository {
  ExpenseRepository({
    required DatabaseHelper databaseHelper,
    required ImageService imageService,
  })  : _db = databaseHelper,
        _imageService = imageService;

  final DatabaseHelper _db;
  final ImageService _imageService;

  @override
  Future<Result<Expense>> addExpense({
    required Expense expense,
    String? imagePath,
  }) async {
    try {
      String? fullPath;
      String? thumbPath;

      // 處理圖片
      if (imagePath != null && imagePath.isNotEmpty) {
        final imageResult = await _imageService.processReceiptImage(
          sourcePath: imagePath,
          expenseDate: expense.date,
        );

        if (imageResult.isFailure) {
          return Result.failure((imageResult as Failure).error);
        }

        final paths = imageResult.getOrThrow();
        fullPath = paths.fullPath;
        thumbPath = paths.thumbnailPath;
      }

      // 建立完整 expense
      final now = DateTime.now();
      final expenseToSave = expense.copyWith(
        receiptImagePath: fullPath,
        thumbnailPath: thumbPath,
        createdAt: now,
        updatedAt: now,
      );

      // 儲存至資料庫
      final id = await _db.insertExpense(expenseToSave.toMap());

      final savedExpense = expenseToSave.copyWith(id: id);
      AppLogger.info('Expense added: id=$id');

      return Result.success(savedExpense);
    } catch (e) {
      AppLogger.error('addExpense failed', error: e);
      return Result.failure(
        DatabaseException.insertFailed(e.toString()),
      );
    }
  }

  @override
  Future<Result<Expense>> updateExpense(Expense expense) async {
    try {
      if (expense.id == null) {
        return Result.failure(
          const ValidationException('無法更新沒有 ID 的支出', code: 'NO_ID'),
        );
      }

      final updatedExpense = expense.copyWith(
        updatedAt: DateTime.now(),
      );

      final rows = await _db.updateExpense(expense.id!, updatedExpense.toMap());
      if (rows == 0) {
        return Result.failure(
          DatabaseException.updateFailed('找不到 ID=${expense.id} 的支出'),
        );
      }

      AppLogger.info('Expense updated: id=${expense.id}');
      return Result.success(updatedExpense);
    } catch (e) {
      AppLogger.error('updateExpense failed', error: e);
      return Result.failure(
        DatabaseException.updateFailed(e.toString()),
      );
    }
  }

  @override
  Future<Result<Expense>> getExpenseById(int id) async {
    try {
      final map = await _db.getExpenseById(id);
      if (map == null) {
        return Result.failure(
          DatabaseException.queryFailed('找不到 ID=$id 的支出'),
        );
      }

      return Result.success(Expense.fromMap(map));
    } catch (e) {
      AppLogger.error('getExpenseById failed', error: e);
      return Result.failure(
        DatabaseException.queryFailed(e.toString()),
      );
    }
  }

  @override
  Future<Result<List<Expense>>> getExpensesByMonth({
    required int year,
    required int month,
    int? limit,
    int? offset,
  }) async {
    try {
      final maps = await _db.getExpensesByMonth(
        year: year,
        month: month,
        includeDeleted: false,
        limit: limit ?? AppConstants.defaultPageSize,
        offset: offset,
      );

      final expenses = maps.map(Expense.fromMap).toList();
      return Result.success(expenses);
    } catch (e) {
      AppLogger.error('getExpensesByMonth failed', error: e);
      return Result.failure(
        DatabaseException.queryFailed(e.toString()),
      );
    }
  }

  @override
  Future<Result<MonthSummary>> getMonthSummary({
    required int year,
    required int month,
  }) async {
    try {
      final map = await _db.getMonthSummary(year, month);

      return Result.success(MonthSummary(
        year: year,
        month: month,
        totalCount: map['total_count'] as int,
        totalHkdAmountCents: map['total_hkd_amount'] as int,
      ));
    } catch (e) {
      AppLogger.error('getMonthSummary failed', error: e);
      return Result.failure(
        DatabaseException.queryFailed(e.toString()),
      );
    }
  }

  @override
  Future<Result<void>> softDeleteExpense(int id) async {
    try {
      // 取得支出確認存在
      final existingMap = await _db.getExpenseById(id);
      if (existingMap == null) {
        return Result.failure(
          DatabaseException.deleteFailed('找不到 ID=$id 的支出'),
        );
      }

      // 更新為已刪除
      final now = DateTime.now();
      await _db.updateExpense(id, {
        'is_deleted': 1,
        'deleted_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      AppLogger.info('Expense soft deleted: id=$id');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('softDeleteExpense failed', error: e);
      return Result.failure(
        DatabaseException.deleteFailed(e.toString()),
      );
    }
  }

  @override
  Future<Result<void>> restoreExpense(int id) async {
    try {
      final now = DateTime.now();
      final rows = await _db.updateExpense(id, {
        'is_deleted': 0,
        'deleted_at': null,
        'updated_at': now.toIso8601String(),
      });

      if (rows == 0) {
        return Result.failure(
          DatabaseException.updateFailed('找不到 ID=$id 的支出'),
        );
      }

      AppLogger.info('Expense restored: id=$id');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('restoreExpense failed', error: e);
      return Result.failure(
        DatabaseException.updateFailed(e.toString()),
      );
    }
  }

  @override
  Future<Result<List<Expense>>> getDeletedExpenses() async {
    try {
      final maps = await _db.getDeletedExpenses();
      final expenses = maps.map(Expense.fromMap).toList();
      return Result.success(expenses);
    } catch (e) {
      AppLogger.error('getDeletedExpenses failed', error: e);
      return Result.failure(
        DatabaseException.queryFailed(e.toString()),
      );
    }
  }

  @override
  Future<Result<void>> permanentlyDeleteExpense(int id) async {
    try {
      // 取得支出以刪除圖片
      final existingMap = await _db.getExpenseById(id);
      if (existingMap == null) {
        return Result.failure(
          DatabaseException.deleteFailed('找不到 ID=$id 的支出'),
        );
      }

      final expense = Expense.fromMap(existingMap);

      // 刪除圖片
      await _imageService.deleteImages(
        fullPath: expense.receiptImagePath,
        thumbnailPath: expense.thumbnailPath,
      );

      // 刪除資料庫記錄
      await _db.deleteExpense(id);

      AppLogger.info('Expense permanently deleted: id=$id');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('permanentlyDeleteExpense failed', error: e);
      return Result.failure(
        DatabaseException.deleteFailed(e.toString()),
      );
    }
  }

  @override
  Future<Result<int>> cleanupExpiredDeletedExpenses() async {
    try {
      // 取得過期的已刪除支出
      final expiredMaps = await _db.getExpiredDeletedExpenses(
        AppConstants.deletedExpenseRetentionDays,
      );

      if (expiredMaps.isEmpty) {
        AppLogger.info('No expired deleted expenses to cleanup');
        return Result.success(0);
      }

      int deletedCount = 0;
      for (final map in expiredMaps) {
        final expense = Expense.fromMap(map);
        // 防護：確保 expense.id 存在
        if (expense.id == null) {
          AppLogger.warning('Skipping expense with null id during cleanup');
          continue;
        }
        final result = await permanentlyDeleteExpense(expense.id!);
        if (result.isSuccess) {
          deletedCount++;
        }
      }

      AppLogger.info('Cleaned up $deletedCount expired deleted expenses');
      return Result.success(deletedCount);
    } catch (e) {
      AppLogger.error('cleanupExpiredDeletedExpenses failed', error: e);
      return Result.failure(
        DatabaseException.deleteFailed(e.toString()),
      );
    }
  }

  @override
  Future<Result<Expense>> replaceReceiptImage({
    required int expenseId,
    required String newImagePath,
  }) async {
    try {
      // 取得現有支出
      final existingResult = await getExpenseById(expenseId);
      if (existingResult.isFailure) {
        return existingResult;
      }

      final existing = existingResult.getOrThrow();

      // 刪除舊圖片
      await _imageService.deleteImages(
        fullPath: existing.receiptImagePath,
        thumbnailPath: existing.thumbnailPath,
      );

      // 處理新圖片
      final imageResult = await _imageService.processReceiptImage(
        sourcePath: newImagePath,
        expenseDate: existing.date,
      );

      if (imageResult.isFailure) {
        return Result.failure((imageResult as Failure).error);
      }

      final paths = imageResult.getOrThrow();

      // 更新支出
      final updatedExpense = existing.copyWith(
        receiptImagePath: paths.fullPath,
        thumbnailPath: paths.thumbnailPath,
        updatedAt: DateTime.now(),
      );

      await _db.updateExpense(expenseId, updatedExpense.toMap());

      AppLogger.info('Receipt image replaced: id=$expenseId');
      return Result.success(updatedExpense);
    } catch (e) {
      AppLogger.error('replaceReceiptImage failed', error: e);
      return Result.failure(
        DatabaseException.updateFailed(e.toString()),
      );
    }
  }
}
