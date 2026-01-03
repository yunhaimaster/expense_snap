import '../constants/validation_rules.dart';
import '../errors/app_exception.dart';
import '../errors/result.dart';

/// 輸入驗證工具類別
class Validators {
  Validators._();

  /// 驗證金額
  ///
  /// 返回以「分」為單位的整數金額
  static Result<int> validateAmount(String? value, {String fieldName = '金額'}) {
    if (value == null || value.isEmpty) {
      return Result.failure(ValidationException.required(fieldName));
    }

    final cleanValue = value.replaceAll(',', '');
    final amount = double.tryParse(cleanValue);

    if (amount == null) {
      return Result.failure(ValidationException.invalidFormat(fieldName));
    }

    if (amount < ValidationRules.minAmount ||
        amount > ValidationRules.maxAmount) {
      return Result.failure(ValidationException.outOfRange(
        fieldName,
        ValidationRules.minAmount,
        ValidationRules.maxAmount,
      ));
    }

    // 檢查小數位數
    final decimalPart = cleanValue.contains('.')
        ? cleanValue.split('.')[1]
        : '';
    if (decimalPart.length > ValidationRules.maxDecimalPlaces) {
      return Result.failure(ValidationException(
        '$fieldName 最多 ${ValidationRules.maxDecimalPlaces} 位小數',
        field: fieldName,
      ));
    }

    // 使用字串解析轉換為分，避免浮點誤差
    // 例如：'123.45' -> 12345, '100' -> 10000
    final cents = _parseAmountToCents(cleanValue);
    return Result.success(cents);
  }

  /// 安全地將金額字串轉換為分（避免浮點誤差）
  static int _parseAmountToCents(String value) {
    final parts = value.split('.');
    final integerPart = int.parse(parts[0]);

    if (parts.length == 1) {
      // 沒有小數部分
      return integerPart * 100;
    }

    // 有小數部分，補齊或截斷到 2 位
    var decimalPart = parts[1];
    if (decimalPart.length == 1) {
      decimalPart = '${decimalPart}0'; // 補 0
    } else if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2); // 截斷
    }

    final decimalValue = int.parse(decimalPart);
    return integerPart * 100 + decimalValue;
  }

  /// 驗證描述
  static Result<String> validateDescription(String? value, {String fieldName = '描述'}) {
    if (value == null || value.trim().isEmpty) {
      return Result.failure(ValidationException.required(fieldName));
    }

    final trimmed = value.trim();

    if (trimmed.length < ValidationRules.minDescriptionLength) {
      return Result.failure(ValidationException.required(fieldName));
    }

    if (trimmed.length > ValidationRules.maxDescriptionLength) {
      return Result.failure(ValidationException.lengthExceeded(
        fieldName,
        ValidationRules.maxDescriptionLength,
      ));
    }

    return Result.success(trimmed);
  }

  /// 驗證匯率（手動輸入）
  static Result<int> validateExchangeRate(String? value, {String fieldName = '匯率'}) {
    if (value == null || value.isEmpty) {
      return Result.failure(ValidationException.required(fieldName));
    }

    final rate = double.tryParse(value);

    if (rate == null) {
      return Result.failure(ValidationException.invalidFormat(fieldName));
    }

    if (rate < ValidationRules.minExchangeRate ||
        rate > ValidationRules.maxExchangeRate) {
      return Result.failure(ValidationException.outOfRange(
        fieldName,
        ValidationRules.minExchangeRate,
        ValidationRules.maxExchangeRate,
      ));
    }

    // 檢查小數位數
    final decimalPart = value.contains('.') ? value.split('.')[1] : '';
    if (decimalPart.length > ValidationRules.maxExchangeRateDecimalPlaces) {
      return Result.failure(ValidationException(
        '$fieldName 最多 ${ValidationRules.maxExchangeRateDecimalPlaces} 位小數',
        field: fieldName,
      ));
    }

    // 轉換為儲存格式（×10⁶）
    final storedRate = (rate * 1000000).round();
    return Result.success(storedRate);
  }

  /// 驗證日期
  static Result<DateTime> validateDate(DateTime? value, {String fieldName = '日期'}) {
    if (value == null) {
      return Result.failure(ValidationException.required(fieldName));
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (value.isAfter(today)) {
      return Result.failure(ValidationException.invalidDate(fieldName));
    }

    return Result.success(value);
  }

  /// 驗證使用者名稱
  static Result<String> validateUserName(String? value, {String fieldName = '名稱'}) {
    if (value == null || value.trim().isEmpty) {
      return Result.failure(ValidationException.required(fieldName));
    }

    final trimmed = value.trim();

    if (trimmed.length < ValidationRules.minUserNameLength) {
      return Result.failure(ValidationException.required(fieldName));
    }

    if (trimmed.length > ValidationRules.maxUserNameLength) {
      return Result.failure(ValidationException.lengthExceeded(
        fieldName,
        ValidationRules.maxUserNameLength,
      ));
    }

    return Result.success(trimmed);
  }

  /// 驗證幣種
  static Result<String> validateCurrency(
    String? value, {
    required List<String> supportedCurrencies,
    String fieldName = '幣種',
  }) {
    if (value == null || value.isEmpty) {
      return Result.failure(ValidationException.required(fieldName));
    }

    if (!supportedCurrencies.contains(value)) {
      return Result.failure(ValidationException(
        '不支援的$fieldName: $value',
        field: fieldName,
      ));
    }

    return Result.success(value);
  }
}
