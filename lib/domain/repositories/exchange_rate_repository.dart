import '../../core/constants/currency_constants.dart';
import '../../core/errors/result.dart';
import '../../data/models/exchange_rate_cache.dart';

/// 匯率 Repository 抽象介面
abstract class IExchangeRateRepository {
  /// 取得匯率（自動處理 fallback 邏輯）
  ///
  /// 返回匯率值和來源
  Future<Result<ExchangeRateResult>> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
  });

  /// 強制刷新匯率（忽略快取）
  Future<Result<ExchangeRateResult>> refreshExchangeRate({
    required String fromCurrency,
    required String toCurrency,
  });

  /// 取得快取的匯率資訊
  Future<ExchangeRateCache?> getCachedRate(String currency);

  /// 檢查是否可以刷新（30 秒冷卻）
  Future<bool> canRefresh();
}

/// 匯率查詢結果
class ExchangeRateResult {
  const ExchangeRateResult({
    required this.rate,
    required this.source,
    this.fetchedAt,
  });

  /// 匯率值（×10⁶ 精度）
  final int rate;

  /// 匯率來源
  final ExchangeRateSource source;

  /// 獲取時間（快取時有效）
  final DateTime? fetchedAt;
}
