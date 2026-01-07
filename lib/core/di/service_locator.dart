import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/secure_storage_helper.dart';
import '../../data/repositories/backup_repository.dart';
import '../../data/repositories/exchange_rate_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../services/image_service.dart';
import '../../services/ocr_service.dart';
import '../utils/app_logger.dart';
import '../utils/path_validator.dart';

/// 服務定位器 - 依賴注入容器
///
/// 管理所有服務和 Repository 的生命週期
class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  bool _initialized = false;

  /// 是否已初始化
  bool get isInitialized => _initialized;

  // 基礎設施服務（使用 late 而非 late final 以支援 reset() 後重新初始化）
  late DatabaseHelper _databaseHelper;
  late SecureStorageHelper _secureStorageHelper;

  // 應用服務
  late ImageService _imageService;
  OcrService? _ocrService; // 延遲初始化，只在使用時建立

  // Repositories
  late ExpenseRepository _expenseRepository;
  late ExchangeRateRepository _exchangeRateRepository;
  late BackupRepository _backupRepository;

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

  /// 圖片服務
  ImageService get imageService {
    _ensureInitialized();
    return _imageService;
  }

  /// OCR 文字識別服務（延遲初始化）
  ///
  /// 只在第一次訪問時建立，避免未使用時佔用資源
  OcrService get ocrService {
    _ensureInitialized();
    return _ocrService ??= OcrService();
  }

  /// 支出 Repository（介面）
  IExpenseRepository get expenseRepository {
    _ensureInitialized();
    return _expenseRepository;
  }

  /// 支出 Repository（實作，用於需要直接存取實作的場景）
  ExpenseRepository get expenseRepositoryImpl {
    _ensureInitialized();
    return _expenseRepository;
  }

  /// 匯率 Repository
  ExchangeRateRepository get exchangeRateRepository {
    _ensureInitialized();
    return _exchangeRateRepository;
  }

  /// 備份 Repository
  BackupRepository get backupRepository {
    _ensureInitialized();
    return _backupRepository;
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

    // 初始化基礎設施
    _databaseHelper = DatabaseHelper.instance;
    await _databaseHelper.database; // 觸發資料庫建立

    _secureStorageHelper = SecureStorageHelper.instance;

    // 初始化應用服務
    _imageService = ImageService();
    // OcrService 採用延遲初始化，不在此處建立

    // 初始化 Repositories（依賴注入）
    _expenseRepository = ExpenseRepository(
      databaseHelper: _databaseHelper,
      imageService: _imageService,
    );

    _exchangeRateRepository = ExchangeRateRepository(
      databaseHelper: _databaseHelper,
    );

    _backupRepository = BackupRepository(
      databaseHelper: _databaseHelper,
    );

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
      // 只有在 OcrService 已建立時才 dispose
      if (_ocrService != null) {
        await _ocrService!.dispose();
        _ocrService = null;
      }
      await _databaseHelper.close();
      _initialized = false;
      AppLogger.info('ServiceLocator reset');
    }
  }
}

/// 全域訪問點
ServiceLocator get sl => ServiceLocator.instance;
