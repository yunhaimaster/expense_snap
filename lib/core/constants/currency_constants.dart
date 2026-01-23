import 'dart:ui';

/// 幣種相關常數
class CurrencyConstants {
  CurrencyConstants._();

  // 預設主要幣種（新使用者的預設值）
  static const String defaultPrimaryCurrency = 'HKD';

  // 預設幣種（新增支出時的預設選項）
  static const String defaultCurrency = 'HKD';

  // 可選擇的主要幣種清單（結算用）
  static const List<String> primaryCurrencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'CNY',
    'HKD', 'TWD', 'KRW', 'SGD', 'AUD',
  ];

  // 支援的幣種清單（所有可輸入的幣種）
  static const List<String> supportedCurrencies = [
    'HKD', 'CNY', 'USD', 'EUR', 'GBP',
    'JPY', 'TWD', 'KRW', 'SGD', 'AUD',
  ];

  // 幣種小數位數（預設 2，JPY/KRW 為 0）
  static const Map<String, int> decimalPlaces = {
    'JPY': 0,
    'KRW': 0,
  };

  /// 取得幣種的小數位數
  static int getDecimalPlaces(String currency) {
    return decimalPlaces[currency] ?? 2;
  }

  // 幣種顯示名稱
  static const Map<String, String> currencyNames = {
    'USD': '美元',
    'EUR': '歐元',
    'GBP': '英鎊',
    'JPY': '日圓',
    'CNY': '人民幣',
    'HKD': '港幣',
    'TWD': '新台幣',
    'KRW': '韓元',
    'SGD': '新加坡幣',
    'AUD': '澳幣',
  };

  // 幣種符號
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CNY': '¥',
    'HKD': 'HK\$',
    'TWD': 'NT\$',
    'KRW': '₩',
    'SGD': 'S\$',
    'AUD': 'A\$',
  };

  /// 根據 locale 推薦幣種
  static String currencyFromLocale(Locale locale) {
    return switch (locale.countryCode) {
      'JP' => 'JPY',
      'KR' => 'KRW',
      'CN' => 'CNY',
      'TW' => 'TWD',
      'SG' => 'SGD',
      'AU' => 'AUD',
      'GB' => 'GBP',
      'US' => 'USD',
      'HK' => 'HKD',
      // 歐元區國家
      'DE' || 'FR' || 'IT' || 'ES' || 'NL' || 'BE' || 'AT' || 'IE' || 'PT' || 'FI' => 'EUR',
      _ => 'HKD', // 預設港幣
    };
  }

  // 預設匯率（當 API 和快取都不可用時）
  // 以 HKD 為基準幣種，precision ×10⁶
  static const Map<String, int> defaultRatesToHkd = {
    'HKD': 1000000, // 1:1
    'CNY': 1089000, // 1 CNY ≈ 1.089 HKD
    'USD': 7800000, // 1 USD ≈ 7.8 HKD
    'EUR': 8500000, // 1 EUR ≈ 8.5 HKD
    'GBP': 9900000, // 1 GBP ≈ 9.9 HKD
    'JPY': 52000,   // 1 JPY ≈ 0.052 HKD
    'TWD': 244000,  // 1 TWD ≈ 0.244 HKD
    'KRW': 5700,    // 1 KRW ≈ 0.0057 HKD
    'SGD': 5800000, // 1 SGD ≈ 5.8 HKD
    'AUD': 5100000, // 1 AUD ≈ 5.1 HKD
  };

  // 預設匯率（double 版本，用於 UI 顯示）
  static const Map<String, double> defaultRates = {
    'HKD': 1.0,
    'CNY': 1.089,
    'USD': 7.8,
    'EUR': 8.5,
    'GBP': 9.9,
    'JPY': 0.052,
    'TWD': 0.244,
    'KRW': 0.0057,
    'SGD': 5.8,
    'AUD': 5.1,
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
