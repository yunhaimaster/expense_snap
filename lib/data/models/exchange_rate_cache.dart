import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';

/// 匯率快取 Model
class ExchangeRateCache {
  const ExchangeRateCache({
    required this.currency,
    required this.rateToHkd,
    required this.fetchedAt,
    required this.source,
  });

  /// 幣種代碼（例如：CNY, USD）
  final String currency;

  /// 兌換港幣的匯率（×10⁶ 精度）
  /// 例如：1 CNY = 1.089 HKD → 儲存為 1089000
  final int rateToHkd;

  /// 獲取時間
  final DateTime fetchedAt;

  /// 匯率來源（primary / fallback）
  final String source;

  /// 是否已過期（超過 24 小時）
  bool get isExpired {
    final now = DateTime.now();
    return now.difference(fetchedAt) > AppConstants.exchangeRateCacheDuration;
  }

  /// 格式化的匯率
  String get formattedRate => Formatters.formatExchangeRate(rateToHkd);

  /// 格式化的獲取時間（相對時間）
  String get formattedFetchedAt => Formatters.formatRelativeTime(fetchedAt);

  /// 從 Map 建立
  factory ExchangeRateCache.fromMap(Map<String, dynamic> map) {
    return ExchangeRateCache(
      currency: map['currency'] as String,
      rateToHkd: map['rate_to_hkd'] as int,
      fetchedAt: DateTime.parse(map['fetched_at'] as String),
      source: map['source'] as String,
    );
  }

  /// 轉換為 Map
  Map<String, dynamic> toMap() {
    return {
      'currency': currency,
      'rate_to_hkd': rateToHkd,
      'fetched_at': Formatters.formatDateForStorage(fetchedAt),
      'source': source,
    };
  }

  /// 複製並修改
  ExchangeRateCache copyWith({
    String? currency,
    int? rateToHkd,
    DateTime? fetchedAt,
    String? source,
  }) {
    return ExchangeRateCache(
      currency: currency ?? this.currency,
      rateToHkd: rateToHkd ?? this.rateToHkd,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExchangeRateCache && other.currency == currency;
  }

  @override
  int get hashCode => currency.hashCode;

  @override
  String toString() {
    return 'ExchangeRateCache(currency: $currency, rate: $formattedRate, '
        'fetchedAt: $formattedFetchedAt, source: $source, expired: $isExpired)';
  }
}
