import '../../core/utils/formatters.dart';

/// 用於 copyWith 中明確設定 null 值的包裝器
class Wrapped<T> {
  const Wrapped(this.value);
  final T value;
}

/// 哨兵值，用於區分「未傳入」和「傳入 null」
class _Sentinel {
  const _Sentinel();
}

/// 備份狀態 Model
class BackupStatus {
  const BackupStatus({
    required this.lastBackupAt,
    required this.lastBackupCount,
    required this.lastBackupSizeKb,
    this.googleEmail,
  });

  /// 最後備份時間
  final DateTime? lastBackupAt;

  /// 最後備份的支出筆數
  final int lastBackupCount;

  /// 最後備份的大小（KB）
  final int lastBackupSizeKb;

  /// Google 帳號 email
  final String? googleEmail;

  /// 是否已連結 Google 帳號
  bool get isGoogleConnected => googleEmail != null && googleEmail!.isNotEmpty;

  /// 格式化的備份時間
  String? get formattedLastBackupAt {
    if (lastBackupAt == null) return null;
    return Formatters.formatRelativeTime(lastBackupAt!);
  }

  /// 格式化的備份大小
  String get formattedSize => Formatters.formatFileSize(lastBackupSizeKb * 1024);

  /// 建立空白狀態
  factory BackupStatus.empty() {
    return const BackupStatus(
      lastBackupAt: null,
      lastBackupCount: 0,
      lastBackupSizeKb: 0,
      googleEmail: null,
    );
  }

  /// 從 Map 建立
  factory BackupStatus.fromMap(Map<String, dynamic> map) {
    return BackupStatus(
      lastBackupAt: map['last_backup_at'] != null
          ? DateTime.parse(map['last_backup_at'] as String)
          : null,
      lastBackupCount: map['last_backup_count'] as int? ?? 0,
      lastBackupSizeKb: map['last_backup_size_kb'] as int? ?? 0,
      googleEmail: map['google_email'] as String?,
    );
  }

  /// 轉換為 Map
  Map<String, dynamic> toMap() {
    return {
      'id': 1, // 永遠只有一筆記錄
      'last_backup_at': lastBackupAt != null
          ? Formatters.formatDateForStorage(lastBackupAt!)
          : null,
      'last_backup_count': lastBackupCount,
      'last_backup_size_kb': lastBackupSizeKb,
      'google_email': googleEmail,
    };
  }

  /// 複製並修改
  ///
  /// 使用 [Wrapped] 可以明確設定 null 值：
  /// ```dart
  /// status.copyWith(googleEmail: Wrapped(null)) // 設定為 null
  /// status.copyWith(googleEmail: Wrapped('email')) // 設定新值
  /// status.copyWith() // 保持原值
  /// ```
  BackupStatus copyWith({
    Object? lastBackupAt = const _Sentinel(),
    int? lastBackupCount,
    int? lastBackupSizeKb,
    Object? googleEmail = const _Sentinel(),
  }) {
    return BackupStatus(
      lastBackupAt: lastBackupAt is _Sentinel
          ? this.lastBackupAt
          : (lastBackupAt is Wrapped<DateTime?>
              ? lastBackupAt.value
              : lastBackupAt as DateTime?),
      lastBackupCount: lastBackupCount ?? this.lastBackupCount,
      lastBackupSizeKb: lastBackupSizeKb ?? this.lastBackupSizeKb,
      googleEmail: googleEmail is _Sentinel
          ? this.googleEmail
          : (googleEmail is Wrapped<String?>
              ? googleEmail.value
              : googleEmail as String?),
    );
  }

  @override
  String toString() {
    return 'BackupStatus(lastBackupAt: $formattedLastBackupAt, '
        'count: $lastBackupCount, size: $formattedSize, '
        'googleEmail: $googleEmail)';
  }
}
