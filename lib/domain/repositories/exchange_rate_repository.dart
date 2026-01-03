import '../../core/constants/currency_constants.dart';
import '../../core/errors/result.dart';

/// 匯率資訊（抽象層）
class ExchangeRateResult {
  const ExchangeRateResult({
    required this.rateToHkd,
    required this.source,
    this.fetchedAt,
  });

  /// 匯率值（×10⁶ 精度）
  final int rateToHkd;

  /// 匯率來源
  final ExchangeRateSource source;

  /// 獲取時間（快取時有效）
  final DateTime? fetchedAt;
}

/// 匯率 Repository 抽象介面
///
/// 定義匯率獲取的契約，實作類別負責處理 fallback 邏輯
abstract class IExchangeRateRepository {
  /// 取得指定幣種對 HKD 的匯率
  ///
  /// 按照 fallback chain 順序嘗試：
  /// 1. 快取有效 → 直接回傳
  /// 2. 快取無效/不存在 → 嘗試 API
  /// 3. API 失敗 + 快取過期 → 使用過期快取
  /// 4. 完全無快取 → 使用預設匯率
  Future<Result<ExchangeRateResult>> getRate(String currency);

  /// 取得所有支援幣種的匯率
  Future<Result<Map<String, ExchangeRateResult>>> getAllRates();

  /// 強制刷新匯率（忽略快取）
  ///
  /// 受 30 秒冷卻限制
  Future<Result<Map<String, ExchangeRateResult>>> refreshRates();

  /// 檢查是否可以刷新（30 秒冷卻）
  bool get canRefresh;

  /// 距離下次可刷新的秒數
  int get secondsUntilRefresh;
}
