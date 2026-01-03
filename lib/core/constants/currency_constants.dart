/// 幣種相關常數
class CurrencyConstants {
  CurrencyConstants._();

  // 主要幣種（報銷結算幣種）
  static const String primaryCurrency = 'HKD';

  // 預設幣種（新增支出時的預設選項）
  static const String defaultCurrency = 'HKD';

  // 支援的幣種清單
  static const List<String> supportedCurrencies = ['HKD', 'CNY', 'USD'];

  // 幣種顯示名稱
  static const Map<String, String> currencyNames = {
    'HKD': '港幣',
    'CNY': '人民幣',
    'USD': '美元',
  };

  // 幣種符號
  static const Map<String, String> currencySymbols = {
    'HKD': 'HK\$',
    'CNY': '¥',
    'USD': '\$',
  };

  // 預設匯率（當 API 和快取都不可用時）
  // 以 HKD 為基準幣種
  static const Map<String, int> defaultRatesToHkd = {
    'HKD': 1000000, // 1:1，精度 ×10⁶
    'CNY': 1089000, // 1 CNY ≈ 1.089 HKD
    'USD': 7800000, // 1 USD ≈ 7.8 HKD
  };

  // 預設匯率（double 版本，用於 UI 顯示）
  static const Map<String, double> defaultRates = {
    'HKD': 1.0,
    'CNY': 1.089,
    'USD': 7.8,
  };

  // 匯率精度（用於儲存和計算）
  static const int ratePrecision = 1000000; // 10^6

  // 金額限制
  static const int minAmountCents = 1; // 0.01 元
  static const int maxAmountCents = 999999999; // 9,999,999.99 元

  // 匯率限制（允許手動輸入的範圍）
  static const double minExchangeRate = 0.0001;
  static const double maxExchangeRate = 9999.9999;
}

/// 匯率來源枚舉
enum ExchangeRateSource {
  /// 從 API 自動取得
  auto,

  /// 使用快取（API 失敗時）
  offline,

  /// 使用預設值（無網絡+快取過期）
  defaultRate,

  /// 使用者手動輸入
  manual,
}

/// 匯率來源擴展方法
extension ExchangeRateSourceExtension on ExchangeRateSource {
  /// 儲存到資料庫的字串值
  String get value {
    switch (this) {
      case ExchangeRateSource.auto:
        return 'auto';
      case ExchangeRateSource.offline:
        return 'offline';
      case ExchangeRateSource.defaultRate:
        return 'default';
      case ExchangeRateSource.manual:
        return 'manual';
    }
  }

  /// 從字串解析
  static ExchangeRateSource fromString(String value) {
    switch (value) {
      case 'auto':
        return ExchangeRateSource.auto;
      case 'offline':
        return ExchangeRateSource.offline;
      case 'default':
        return ExchangeRateSource.defaultRate;
      case 'manual':
        return ExchangeRateSource.manual;
      default:
        return ExchangeRateSource.defaultRate;
    }
  }

  /// 顯示用標籤
  String get label {
    switch (this) {
      case ExchangeRateSource.auto:
        return '即時匯率';
      case ExchangeRateSource.offline:
        return '離線匯率';
      case ExchangeRateSource.defaultRate:
        return '預設匯率';
      case ExchangeRateSource.manual:
        return '手動輸入';
    }
  }
}
