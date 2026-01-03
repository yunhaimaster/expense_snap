import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/secure_storage_helper.dart';
import '../utils/app_logger.dart';
import '../utils/path_validator.dart';

/// 服務定位器 - 簡易依賴注入
///
/// Phase 1 僅包含基礎設施，具體 Repository 實作在後續 Phase 新增
class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  bool _initialized = false;

  /// 是否已初始化
  bool get isInitialized => _initialized;

  // 基礎設施服務
  late final DatabaseHelper _databaseHelper;
  late final SecureStorageHelper _secureStorageHelper;

  /// 資料庫助手
  DatabaseHelper get databaseHelper {
    _ensureInitialized();
    return _databaseHelper;
  }

  /// 安全儲存助手
  SecureStorageHelper get secureStorageHelper {
    _ensureInitialized();
    return _secureStorageHelper;
  }

  /// 初始化所有服務
  ///
  /// 應在 main() 中最先呼叫
  Future<void> initialize() async {
    if (_initialized) {
      AppLogger.warning('ServiceLocator already initialized');
      return;
    }

    AppLogger.info('Initializing ServiceLocator...');

    // 初始化路徑驗證器
    await PathValidator.initialize();

    // 初始化資料庫
    _databaseHelper = DatabaseHelper.instance;
    await _databaseHelper.database; // 觸發資料庫建立

    // 初始化安全儲存
    _secureStorageHelper = SecureStorageHelper.instance;

    _initialized = true;
    AppLogger.info('ServiceLocator initialized successfully');
  }

  /// 確保已初始化
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'ServiceLocator not initialized. Call initialize() first.',
      );
    }
  }

  /// 重置（僅用於測試）
  Future<void> reset() async {
    if (_initialized) {
      await _databaseHelper.close();
      _initialized = false;
      AppLogger.info('ServiceLocator reset');
    }
  }
}

/// 全域訪問點
ServiceLocator get sl => ServiceLocator.instance;
