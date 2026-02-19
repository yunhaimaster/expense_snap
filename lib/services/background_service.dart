import 'package:workmanager/workmanager.dart';

import '../core/di/service_locator.dart';
import '../core/utils/app_logger.dart';
import '../data/repositories/expense_repository.dart';
import 'image_service.dart';

/// 背景任務回調分發器
///
/// 必須是頂層函數，不能是類別方法
/// 回傳 false 時 WorkManager 會依據 backoffPolicy 自動重試
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    AppLogger.info('Background task started: $taskName');

    try {
      // 初始化服務定位器
      await ServiceLocator.instance.initialize();

      switch (taskName) {
        case BackgroundService.cleanupTaskName:
          await BackgroundService.performCleanup();
          break;
        default:
          AppLogger.warning('Unknown background task: $taskName');
          // 未知任務不重試
          return true;
      }

      AppLogger.info('Background task completed: $taskName');
      return true;
    } on Exception catch (e, stackTrace) {
      AppLogger.error(
        'Background task failed: $taskName',
        error: e,
        stackTrace: stackTrace,
      );
      // 回傳 false 觸發 WorkManager 指數退避重試
      return false;
    }
  });
}

/// 背景服務
///
/// 管理背景任務的註冊和執行
class BackgroundService {
  BackgroundService._();

  /// 清理任務 ID
  static const String cleanupTaskId = 'expense_snap_cleanup';

  /// 清理任務名稱
  static const String cleanupTaskName = 'cleanupDeletedExpenses';

  /// 重試初始退避延遲（WorkManager 指數退避基準）
  static const Duration initialBackoffDelay = Duration(minutes: 15);

  /// 手動觸發清理
  static Future<int> triggerManualCleanup() async {
    return await performCleanup();
  }

  /// 執行清理邏輯
  ///
  /// 清理失敗時拋出異常，讓 callbackDispatcher 觸發 WorkManager 重試
  static Future<int> performCleanup() async {
    var cleanedCount = 0;

    final imageService = ImageService();
    final expenseRepository = ExpenseRepository(
      databaseHelper: sl.databaseHelper,
      imageService: imageService,
    );

    // 清理已刪除超過 30 天的支出
    final cleanupResult = await expenseRepository
        .cleanupExpiredDeletedExpenses();
    cleanupResult.fold(
      onFailure: (e) =>
          AppLogger.warning('Cleanup expenses failed: ${e.message}'),
      onSuccess: (count) {
        cleanedCount = count;
        AppLogger.info('Cleaned up $cleanedCount deleted expenses');
      },
    );

    // 清理匯出臨時檔案（非關鍵，失敗僅記錄）
    try {
      await imageService.cleanupTempFiles();
      AppLogger.info('Cleaned up temp export files');
    } on Exception catch (e) {
      AppLogger.warning('Temp file cleanup failed: $e');
    }

    // 記錄清理時間
    await sl.databaseHelper.setSetting(
      'last_cleanup_at',
      DateTime.now().toIso8601String(),
    );

    return cleanedCount;
  }

  /// 取消所有背景任務
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    AppLogger.info('All background tasks cancelled');
  }

  /// 立即執行一次清理任務（失敗時指數退避重試）
  static Future<void> scheduleImmediateCleanup() async {
    await Workmanager().registerOneOffTask(
      '${cleanupTaskId}_immediate',
      cleanupTaskName,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: initialBackoffDelay,
    );
    AppLogger.info('Immediate cleanup scheduled');
  }
}
