import 'package:dio/dio.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/currency_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/app_logger.dart';

/// 暫時性錯誤重試攔截器（僅重試一次）
///
/// 針對 5xx 伺服器錯誤和逾時錯誤自動重試
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;

  /// 判斷是否為可重試的暫時性錯誤
  static bool _isTransient(DioException err) {
    // 逾時錯誤
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }
    // 5xx 伺服器錯誤
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return true;
    }
    return false;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 已重試過則不再重試
    if (err.requestOptions.extra['_retried'] == true) {
      handler.next(err);
      return;
    }

    if (!_isTransient(err)) {
      handler.next(err);
      return;
    }

    AppLogger.info('Retrying request: ${err.requestOptions.uri}');

    try {
      // 標記已重試，延遲後重試
      err.requestOptions.extra['_retried'] = true;
      await Future<void>.delayed(ApiConfig.retryDelay);
      final response = await _dio.fetch(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    } on Object catch (e) {
      // 非 Dio 例外（如 SocketException）包裝為 DioException
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}

/// 匯率 API 資料來源
///
/// 使用 fawazahmed0/currency-api，支援主要和備用 CDN
/// 內建速率限制防止過於頻繁的 API 呼叫
class ExchangeRateApi {
  ExchangeRateApi({Dio? dio}) : _dio = dio ?? _createDio();

  final Dio _dio;

  /// 速率限制：最小間隔（秒）
  static const int _minIntervalSeconds = 5;

  /// 上次請求時間
  DateTime? _lastRequestTime;

  /// 建立 Dio 實例（含重試攔截器）
  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
      ),
    );
    dio.interceptors.add(_RetryInterceptor(dio));
    return dio;
  }

  /// 檢查是否受速率限制
  bool get _isRateLimited {
    if (_lastRequestTime == null) return false;
    final elapsed = DateTime.now().difference(_lastRequestTime!);
    return elapsed.inSeconds < _minIntervalSeconds;
  }

  /// 取得指定幣種對基準幣種的匯率
  ///
  /// [baseCurrency] 基準幣種（預設 HKD）
  ///
  /// 會先嘗試主要 API，失敗後自動切換到備用 API
  /// 回傳：{幣種: 匯率(×10⁶), ...}
  ///
  /// 注意：內建速率限制，若距上次請求不足 5 秒會回傳錯誤
  Future<Result<Map<String, int>>> fetchRates({
    String baseCurrency = 'HKD',
  }) async {
    // 速率限制檢查
    if (_isRateLimited) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      final remaining = _minIntervalSeconds - elapsed.inSeconds;
      AppLogger.warning('Rate limited, please wait $remaining seconds');
      return Result.failure(
        NetworkException(
          '請求過於頻繁，請 $remaining 秒後再試',
          code: 'RATE_LIMITED',
        ),
      );
    }

    // 記錄請求時間
    _lastRequestTime = DateTime.now();
    // 嘗試主要 API
    final primaryResult = await _fetchFromUrl(
      ApiConfig.primaryExchangeRateApi,
      'primary',
      baseCurrency,
    );

    if (primaryResult.isSuccess) {
      return primaryResult;
    }

    // 主要 API 失敗，嘗試備用 API
    AppLogger.warning('Primary API failed, trying fallback API');
    return await _fetchFromUrl(
      ApiConfig.fallbackExchangeRateApi,
      'fallback',
      baseCurrency,
    );
  }

  /// 從指定 URL 獲取匯率
  Future<Result<Map<String, int>>> _fetchFromUrl(
    String baseUrl,
    String source,
    String baseCurrency,
  ) async {
    try {
      // API 格式：{baseUrl}/{baseCurrency}.json
      // 回傳以 baseCurrency 為基準的其他幣種匯率
      final url = '$baseUrl/${baseCurrency.toLowerCase()}.json';

      AppLogger.network('GET', url);

      final response = await _dio.get(url);

      if (response.statusCode != 200) {
        AppLogger.network('GET', url, statusCode: response.statusCode);
        return Result.failure(
          NetworkException.serverError(statusCode: response.statusCode),
        );
      }

      // 解析回應（安全類型檢查）
      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        AppLogger.error('Invalid response type: ${responseData.runtimeType}');
        return Result.failure(
          const NetworkException('Invalid API response format'),
        );
      }
      final baseLower = baseCurrency.toLowerCase();
      final baseRates = responseData[baseLower] as Map<String, dynamic>?;

      if (baseRates == null) {
        return Result.failure(
          NetworkException('Missing $baseCurrency rates in API response'),
        );
      }

      // 轉換為 Map<String, int>，以 ×10⁶ 精度儲存
      // 注意：API 回傳的是 1 baseCurrency = X currency
      // 我們需要的是 1 currency = X baseCurrency（反向）
      final rates = <String, int>{};

      for (final currency in CurrencyConstants.supportedCurrencies) {
        if (currency == baseCurrency) {
          // 相同幣種固定 1:1
          rates[currency] = CurrencyConstants.ratePrecision;
        } else {
          final currencyLower = currency.toLowerCase();
          final rateFromBase = baseRates[currencyLower];

          if (rateFromBase != null) {
            // API 回傳 1 baseCurrency = X currency
            // 反向計算 1 currency = (1/X) baseCurrency
            final rateValue = (rateFromBase as num).toDouble();
            if (rateValue > 0) {
              final rateToBase = 1.0 / rateValue;
              // 轉換為 ×10⁶ 精度的整數
              rates[currency] = (rateToBase * CurrencyConstants.ratePrecision)
                  .round();
            }
          }
        }
      }

      AppLogger.info(
        'Fetched ${rates.length} exchange rates from $source API',
      );

      return Result.success(rates);
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to fetch exchange rates from $source',
        error: e,
      );

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return Result.failure(NetworkException.timeout());
      }

      if (e.type == DioExceptionType.connectionError) {
        return Result.failure(NetworkException.noConnection());
      }

      return Result.failure(
        NetworkException(
          e.message ?? 'Network error',
          statusCode: e.response?.statusCode,
        ),
      );
    } on Exception catch (e) {
      AppLogger.error('Unexpected error fetching rates from $source', error: e);
      return Result.failure(NetworkException('Unexpected error: $e'));
    }
  }
}
