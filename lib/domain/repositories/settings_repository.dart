import '../../core/errors/result.dart';
import '../../data/models/app_settings.dart';

/// 設定 Repository 抽象介面
abstract class ISettingsRepository {
  /// 取得所有設定
  Future<Result<AppSettings>> getSettings();

  /// 儲存使用者名稱
  Future<Result<void>> saveUserName(String name);

  /// 標記 Onboarding 完成
  Future<Result<void>> markOnboardingCompleted();

  /// 更新最後清理時間
  Future<Result<void>> updateLastCleanupTime();

  /// 更新最後匯率刷新時間
  Future<Result<void>> updateLastRateRefreshTime();

  /// 檢查是否需要清理（距離上次清理超過 7 天）
  Future<bool> shouldRunCleanup();
}
