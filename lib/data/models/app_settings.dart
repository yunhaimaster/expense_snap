/// App 設定鍵值
class AppSettingsKey {
  AppSettingsKey._();

  /// 使用者名稱（匯出檔名使用）
  static const String userName = 'user_name';

  /// 首次啟動標記
  static const String onboardingCompleted = 'onboarding_completed';

  /// 上次清理時間
  static const String lastCleanupAt = 'last_cleanup_at';

  /// 上次匯率刷新時間（用於冷卻計算）
  static const String lastRateRefreshAt = 'last_rate_refresh_at';
}

/// App 設定 Model
class AppSettings {
  const AppSettings({
    required this.userName,
    required this.onboardingCompleted,
    this.lastCleanupAt,
    this.lastRateRefreshAt,
  });

  /// 使用者名稱
  final String userName;

  /// 是否已完成 Onboarding
  final bool onboardingCompleted;

  /// 上次清理時間
  final DateTime? lastCleanupAt;

  /// 上次匯率刷新時間
  final DateTime? lastRateRefreshAt;

  /// 建立預設設定
  factory AppSettings.defaults() {
    return const AppSettings(
      userName: '員工',
      onboardingCompleted: false,
      lastCleanupAt: null,
      lastRateRefreshAt: null,
    );
  }

  /// 從 Map 建立（從資料庫讀取的 key-value 對）
  factory AppSettings.fromKeyValueMap(Map<String, String?> map) {
    return AppSettings(
      userName: map[AppSettingsKey.userName] ?? '員工',
      onboardingCompleted:
          map[AppSettingsKey.onboardingCompleted] == 'true',
      lastCleanupAt: map[AppSettingsKey.lastCleanupAt] != null
          ? DateTime.tryParse(map[AppSettingsKey.lastCleanupAt]!)
          : null,
      lastRateRefreshAt: map[AppSettingsKey.lastRateRefreshAt] != null
          ? DateTime.tryParse(map[AppSettingsKey.lastRateRefreshAt]!)
          : null,
    );
  }

  /// 轉換為 Map（用於批量儲存）
  Map<String, String> toKeyValueMap() {
    return {
      AppSettingsKey.userName: userName,
      AppSettingsKey.onboardingCompleted: onboardingCompleted.toString(),
      if (lastCleanupAt != null)
        AppSettingsKey.lastCleanupAt: lastCleanupAt!.toIso8601String(),
      if (lastRateRefreshAt != null)
        AppSettingsKey.lastRateRefreshAt: lastRateRefreshAt!.toIso8601String(),
    };
  }

  /// 複製並修改
  AppSettings copyWith({
    String? userName,
    bool? onboardingCompleted,
    DateTime? lastCleanupAt,
    DateTime? lastRateRefreshAt,
  }) {
    return AppSettings(
      userName: userName ?? this.userName,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      lastCleanupAt: lastCleanupAt ?? this.lastCleanupAt,
      lastRateRefreshAt: lastRateRefreshAt ?? this.lastRateRefreshAt,
    );
  }

  @override
  String toString() {
    return 'AppSettings(userName: $userName, onboardingCompleted: $onboardingCompleted)';
  }
}
