import 'package:flutter/foundation.dart';

import '../../core/constants/currency_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/exchange_rate_repository.dart';

/// 匯率狀態 Provider
///
/// 管理匯率獲取、快取和 UI 狀態
class ExchangeRateProvider extends ChangeNotifier {
  ExchangeRateProvider({ExchangeRateRepository? repository})
      : _repository = repository ?? ExchangeRateRepository();

  final ExchangeRateRepository _repository;

  /// 匯率資訊快取（幣種 → 資訊）
  final Map<String, ExchangeRateInfo> _rates = {};

  // 是否已 dispose
  bool _disposed = false;

  /// 是否正在載入
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 錯誤訊息
  AppException? _error;
  AppException? get error => _error;

  /// 是否可以重新整理
  bool get canRefresh => _repository.canRefresh;

  /// 距離下次可重新整理的秒數
  int get secondsUntilRefresh => _repository.secondsUntilRefresh;

  /// 取得指定幣種的匯率資訊
  ExchangeRateInfo? getRate(String currency) => _rates[currency];

  /// 取得所有匯率
  Map<String, ExchangeRateInfo> get rates => Map.unmodifiable(_rates);

  /// 載入指定幣種的匯率
  Future<ExchangeRateInfo?> loadRate(String currency) async {
    // HKD 固定 1:1
    if (currency == 'HKD') {
      final info = ExchangeRateInfo(
        rateToHkd: CurrencyConstants.ratePrecision,
        source: ExchangeRateSource.auto,
        fetchedAt: DateTime.now(),
      );
      _rates[currency] = info;
      return info;
    }

    // 如果已有快取且在 5 分鐘內，直接返回（避免重複請求）
    // 注意：這是 Provider 層的內存快取，不是 Repository 的持久快取
    final cached = _rates[currency];
    if (cached != null && cached.fetchedAt != null) {
      final elapsed = DateTime.now().difference(cached.fetchedAt!);
      if (elapsed < const Duration(minutes: 5)) {
        return cached;
      }
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final result = await _repository.getRate(currency);

      return result.fold(
        onFailure: (error) {
          _error = error;
          AppLogger.warning(
              'Failed to load rate for $currency: ${error.message}');
          return null;
        },
        onSuccess: (info) {
          _rates[currency] = info;
          return info;
        },
      );
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// 載入所有支援幣種的匯率
  Future<void> loadAllRates() async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final result = await _repository.getAllRates();

      result.fold(
        onFailure: (error) {
          _error = error;
          AppLogger.warning('Failed to load all rates: ${error.message}');
        },
        onSuccess: (ratesMap) {
          _rates.clear();
          _rates.addAll(ratesMap);
        },
      );
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// 強制重新整理所有匯率
  ///
  /// [forceRefresh] 如果為 true，則繞過 30 秒冷卻限制（用於長按刷新）
  Future<bool> refreshRates({bool forceRefresh = false}) async {
    if (!forceRefresh && !canRefresh) {
      _error = NetworkException(
        '請稍候 $secondsUntilRefresh 秒後再試',
        code: 'COOLDOWN',
      );
      _safeNotifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final result = await _repository.refreshRates(forceRefresh: forceRefresh);

      return result.fold(
        onFailure: (error) {
          _error = error;
          AppLogger.warning('Failed to refresh rates: ${error.message}');
          return false;
        },
        onSuccess: (ratesMap) {
          _rates.clear();
          _rates.addAll(ratesMap);
          if (forceRefresh) {
            AppLogger.info('Exchange rates force refreshed successfully');
          }
          return true;
        },
      );
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// 清除匯率快取
  Future<void> invalidateCache() async {
    await _repository.invalidateCache();
    _rates.clear();
    _safeNotifyListeners();
  }

  /// 清除錯誤
  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }

  /// 安全的 notifyListeners（防止 dispose 後呼叫）
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    AppLogger.debug('ExchangeRateProvider disposed');
    super.dispose();
  }
}
