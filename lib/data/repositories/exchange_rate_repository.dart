import '../../core/constants/app_constants.dart';
import '../../core/constants/currency_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/result.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/formatters.dart';
import '../datasources/local/database_helper.dart';
import '../datasources/remote/exchange_rate_api.dart';
import '../models/exchange_rate_cache.dart';

/// 匯率來源資訊
class ExchangeRateInfo {
  const ExchangeRateInfo({
    required this.rate,
    required this.source,
    this.baseCurrency = CurrencyConstants.defaultPrimaryCurrency,
    this.fetchedAt,
  });

  /// 匯率（×10⁶ 精度）
  final int rate;

  /// 基準幣種
  final String baseCurrency;

  /// 來源
  final ExchangeRateSource source;

  /// 獲取時間（僅 auto/offline 有值）
  final DateTime? fetchedAt;

  /// 格式化的匯率
  String get formattedRate => Formatters.formatExchangeRate(rate);

  /// 格式化的相對時間
  String? get formattedFetchedAt =>
      fetchedAt != null ? Formatters.formatRelativeTime(fetchedAt!) : null;
}

/// 匯率儲存庫
///
/// 實作三層 fallback 機制：
/// 1. Online API (Primary + Fallback CDN)
/// 2. SQLite Cache (24h valid)
/// 3. Default Hardcoded Rates
class ExchangeRateRepository {
  ExchangeRateRepository({
    DatabaseHelper? databaseHelper,
    ExchangeRateApi? api,
  }) : _db = databaseHelper ?? DatabaseHelper.instance,
       _api = api ?? ExchangeRateApi();

  final DatabaseHelper _db;
  final ExchangeRateApi _api;

  /// 上次重新整理時間（用於 30 秒冷卻）
  DateTime? _lastRefreshTime;

  /// 是否可以重新整理（30 秒冷卻）
  bool get canRefresh {
    if (_lastRefreshTime == null) return true;
    final elapsed = DateTime.now().difference(_lastRefreshTime!);
    return elapsed >= AppConstants.minExchangeRateRefreshInterval;
  }

  /// 距離下次可重新整理的秒數
  int get secondsUntilRefresh {
    if (canRefresh) return 0;
    final elapsed = DateTime.now().difference(_lastRefreshTime!);
    final remaining =
        AppConstants.minExchangeRateRefreshInterval.inSeconds -
        elapsed.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// 取得指定幣種的匯率
  ///
  /// [currency] 來源幣種
  /// [baseCurrency] 目標幣種（預設為用戶主要幣種）
  ///
  /// 按照 fallback chain 順序嘗試：
  /// 1. 快取有效 → 直接回傳
  /// 2. 快取無效/不存在 → 嘗試 API
  /// 3. API 失敗 + 快取過期 → 使用過期快取
  /// 4. 完全無快取 → 使用預設匯率
  Future<Result<ExchangeRateInfo>> getRate(
    String currency, {
    String baseCurrency = CurrencyConstants.defaultPrimaryCurrency,
  }) async {
    // 相同幣種固定 1:1
    if (currency == baseCurrency) {
      return Result.success(
        ExchangeRateInfo(
          rate: CurrencyConstants.ratePrecision,
          baseCurrency: baseCurrency,
          source: ExchangeRateSource.auto,
          fetchedAt: DateTime.now(),
        ),
      );
    }

    // 1. 檢查快取
    final cacheResult = await _getCachedRate(currency, baseCurrency);
    if (cacheResult != null && !cacheResult.isExpired) {
      AppLogger.debug('Using valid cached rate for $currency to $baseCurrency');
      return Result.success(
        ExchangeRateInfo(
          rate: cacheResult.rate,
          baseCurrency: baseCurrency,
          source: ExchangeRateSource.auto,
          fetchedAt: cacheResult.fetchedAt,
        ),
      );
    }

    // 2. 嘗試從 API 獲取新匯率
    final apiResult = await _api.fetchRates(baseCurrency: baseCurrency);

    if (apiResult.isSuccess) {
      final rates = apiResult.getOrThrow();

      if (rates.containsKey(currency)) {
        // 更新快取
        await _cacheRates(rates, 'primary', baseCurrency);

        _lastRefreshTime = DateTime.now();

        return Result.success(
          ExchangeRateInfo(
            rate: rates[currency]!,
            baseCurrency: baseCurrency,
            source: ExchangeRateSource.auto,
            fetchedAt: DateTime.now(),
          ),
        );
      }
    }

    // 3. API 失敗，檢查是否有過期快取可用
    if (cacheResult != null) {
      AppLogger.warning('API failed, using expired cache for $currency');
      return Result.success(
        ExchangeRateInfo(
          rate: cacheResult.rate,
          baseCurrency: baseCurrency,
          source: ExchangeRateSource.offline,
          fetchedAt: cacheResult.fetchedAt,
        ),
      );
    }

    // 4. 完全無快取，使用預設匯率
    final defaultRate = _getDefaultRate(currency, baseCurrency);
    if (defaultRate != null) {
      AppLogger.warning('Using default rate for $currency to $baseCurrency');
      return Result.success(
        ExchangeRateInfo(
          rate: defaultRate,
          baseCurrency: baseCurrency,
          source: ExchangeRateSource.defaultRate,
        ),
      );
    }

    // 不支援的幣種
    return Result.failure(
      ValidationException('Unsupported currency: $currency'),
    );
  }

  /// 取得預設匯率（支援任意基準幣種）
  int? _getDefaultRate(String currency, String baseCurrency) {
    if (baseCurrency == 'HKD') {
      return CurrencyConstants.defaultRatesToHkd[currency];
    }

    // 跨幣種：先轉 HKD，再轉目標幣種
    final currencyToHkd = CurrencyConstants.defaultRatesToHkd[currency];
    final baseToHkd = CurrencyConstants.defaultRatesToHkd[baseCurrency];

    if (currencyToHkd == null || baseToHkd == null) return null;

    // rate = currencyToHkd / baseToHkd
    // 使用高精度計算避免溢位
    return ((currencyToHkd / baseToHkd) * CurrencyConstants.ratePrecision)
        .round();
  }

  /// 強制重新整理匯率（忽略快取）
  ///
  /// [baseCurrency] 基準幣種（預設為用戶主要幣種）
  /// [forceRefresh] 如果為 true，則繞過 30 秒冷卻限制（用於長按刷新）
  Future<Result<Map<String, ExchangeRateInfo>>> refreshRates({
    String baseCurrency = CurrencyConstants.defaultPrimaryCurrency,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && !canRefresh) {
      return Result.failure(
        NetworkException(
          '請稍候 $secondsUntilRefresh 秒後再試',
          code: 'COOLDOWN',
        ),
      );
    }

    if (forceRefresh) {
      AppLogger.info('Force refresh requested, bypassing cooldown');
    }

    final apiResult = await _api.fetchRates(baseCurrency: baseCurrency);

    if (apiResult.isFailure) {
      return Result.failure(
        apiResult.fold(
          onFailure: (e) => e,
          onSuccess: (_) => throw StateError('Unreachable'),
        ),
      );
    }

    final rates = apiResult.getOrThrow();

    // 更新快取
    await _cacheRates(rates, 'primary', baseCurrency);

    _lastRefreshTime = DateTime.now();

    // 轉換為 ExchangeRateInfo map
    final infoMap = <String, ExchangeRateInfo>{};
    for (final entry in rates.entries) {
      infoMap[entry.key] = ExchangeRateInfo(
        rate: entry.value,
        baseCurrency: baseCurrency,
        source: ExchangeRateSource.auto,
        fetchedAt: DateTime.now(),
      );
    }

    return Result.success(infoMap);
  }

  /// 清除快取（測試用或手動清除）
  Future<void> invalidateCache() async {
    try {
      await _db.clearExchangeRateCache();
      _lastRefreshTime = null;
      AppLogger.info('Exchange rate cache invalidated');
    } catch (e) {
      AppLogger.error('Failed to invalidate cache', error: e);
    }
  }

  /// 取得所有支援幣種的匯率
  Future<Result<Map<String, ExchangeRateInfo>>> getAllRates({
    String baseCurrency = CurrencyConstants.defaultPrimaryCurrency,
  }) async {
    final result = <String, ExchangeRateInfo>{};

    for (final currency in CurrencyConstants.supportedCurrencies) {
      final rateResult = await getRate(currency, baseCurrency: baseCurrency);
      rateResult.fold(
        onFailure: (error) {
          // 使用預設值作為最後保障
          final defaultRate =
              _getDefaultRate(currency, baseCurrency) ??
              CurrencyConstants.ratePrecision;
          result[currency] = ExchangeRateInfo(
            rate: defaultRate,
            baseCurrency: baseCurrency,
            source: ExchangeRateSource.defaultRate,
          );
        },
        onSuccess: (info) {
          result[currency] = info;
        },
      );
    }

    return Result.success(result);
  }

  /// 從快取取得匯率
  Future<ExchangeRateCache?> _getCachedRate(
    String currency,
    String baseCurrency,
  ) async {
    try {
      final map = await _db.getExchangeRateCache(
        currency,
        baseCurrency: baseCurrency,
      );
      if (map == null) return null;
      return ExchangeRateCache.fromMap(map);
    } catch (e) {
      AppLogger.error('Failed to get cached rate', error: e);
      return null;
    }
  }

  /// 儲存匯率到快取
  Future<void> _cacheRates(
    Map<String, int> rates,
    String source,
    String baseCurrency,
  ) async {
    try {
      final now = DateTime.now();

      for (final entry in rates.entries) {
        final cache = ExchangeRateCache(
          currency: entry.key,
          baseCurrency: baseCurrency,
          rate: entry.value,
          fetchedAt: now,
          source: source,
        );
        await _db.upsertExchangeRateCache(cache.toMap());
      }

      AppLogger.debug(
        'Cached ${rates.length} exchange rates for $baseCurrency',
      );
    } catch (e) {
      AppLogger.error('Failed to cache rates', error: e);
    }
  }
}
