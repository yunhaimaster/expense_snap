import 'package:dio/dio.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/currency_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/app_logger.dart';

/// 匯率 API 資料來源
///
/// 使用 fawazahmed0/currency-api，支援主要和備用 CDN
class ExchangeRateApi {
  ExchangeRateApi({Dio? dio}) : _dio = dio ?? _createDio();

  final Dio _dio;

  /// 建立 Dio 實例
  static Dio _createDio() {
    return Dio(
      BaseOptions(
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
      ),
    );
  }

  /// 取得指定幣種對港幣的匯率
  ///
  /// 會先嘗試主要 API，失敗後自動切換到備用 API
  /// 回傳：{幣種: 匯率(×10⁶), ...}
  Future<Result<Map<String, int>>> fetchRates() async {
    // 嘗試主要 API
    final primaryResult = await _fetchFromUrl(
      ApiConfig.primaryExchangeRateApi,
      'primary',
    );

    if (primaryResult.isSuccess) {
      return primaryResult;
    }

    // 主要 API 失敗，嘗試備用 API
    AppLogger.warning('Primary API failed, trying fallback API');
    return await _fetchFromUrl(
      ApiConfig.fallbackExchangeRateApi,
      'fallback',
    );
  }

  /// 從指定 URL 獲取匯率
  Future<Result<Map<String, int>>> _fetchFromUrl(
    String baseUrl,
    String source,
  ) async {
    try {
      // API 格式：{baseUrl}/hkd.json
      // 回傳以 HKD 為基準的其他幣種匯率
      final url = '$baseUrl/hkd.json';

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
      final hkdRates = responseData['hkd'] as Map<String, dynamic>?;

      if (hkdRates == null) {
        return Result.failure(
          const NetworkException('Missing HKD rates in API response'),
        );
      }

      // 轉換為 Map<String, int>，以 ×10⁶ 精度儲存
      // 注意：API 回傳的是 1 HKD = X currency
      // 我們需要的是 1 currency = X HKD（反向）
      final rates = <String, int>{};

      for (final currency in CurrencyConstants.supportedCurrencies) {
        if (currency == 'HKD') {
          // HKD 對 HKD 固定 1:1
          rates[currency] = CurrencyConstants.ratePrecision;
        } else {
          final currencyLower = currency.toLowerCase();
          final rateFromHkd = hkdRates[currencyLower];

          if (rateFromHkd != null) {
            // API 回傳 1 HKD = X currency
            // 反向計算 1 currency = (1/X) HKD
            final rateValue = (rateFromHkd as num).toDouble();
            if (rateValue > 0) {
              final rateToHkd = 1.0 / rateValue;
              // 轉換為 ×10⁶ 精度的整數
              rates[currency] =
                  (rateToHkd * CurrencyConstants.ratePrecision).round();
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
    } catch (e) {
      AppLogger.error('Unexpected error fetching rates from $source', error: e);
      return Result.failure(NetworkException('Unexpected error: $e'));
    }
  }
}
