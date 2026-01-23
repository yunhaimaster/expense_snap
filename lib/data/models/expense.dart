import '../../core/constants/currency_constants.dart';
import '../../core/constants/expense_category.dart';
import '../../core/utils/formatters.dart';

/// 支出記錄 Model
///
/// 金額以「分」儲存，避免浮點誤差
/// 匯率以 ×10⁶ 精度儲存
class Expense {
  const Expense({
    this.id,
    required this.date,
    required this.originalAmountCents,
    required this.originalCurrency,
    required this.exchangeRate,
    required this.exchangeRateSource,
    required this.convertedAmountCents,
    required this.targetCurrency,
    required this.description,
    this.category,
    this.receiptImagePath,
    this.thumbnailPath,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 資料庫 ID（新建時為 null）
  final int? id;

  /// 支出日期
  final DateTime date;

  /// 原始金額（以分為單位）
  final int originalAmountCents;

  /// 原始幣種
  final String originalCurrency;

  /// 匯率（×10⁶ 精度）
  final int exchangeRate;

  /// 匯率來源
  final ExchangeRateSource exchangeRateSource;

  /// 轉換後金額（以分為單位，目標幣種為 targetCurrency）
  final int convertedAmountCents;

  /// 目標幣種（用戶的主要幣種）
  final String targetCurrency;

  /// 描述
  final String description;

  /// 支出分類（nullable，選填）
  final ExpenseCategory? category;

  /// 原圖路徑
  final String? receiptImagePath;

  /// 縮圖路徑
  final String? thumbnailPath;

  /// 是否已刪除（軟刪除）
  final bool isDeleted;

  /// 刪除時間（用於 30 天後清理）
  final DateTime? deletedAt;

  /// 建立時間
  final DateTime createdAt;

  /// 更新時間
  final DateTime updatedAt;

  // 計算屬性

  /// 原始金額（元）- 尊重原始幣種的小數位數
  double get originalAmount =>
      Formatters.centsToAmount(originalAmountCents, originalCurrency);

  /// 轉換後金額（元）- 使用 targetCurrency 決定小數位數
  double get convertedAmount =>
      Formatters.centsToAmount(convertedAmountCents, targetCurrency);

  /// 格式化的原始金額
  String get formattedOriginalAmount =>
      Formatters.formatAmount(originalAmountCents, originalCurrency);

  /// 格式化的轉換後金額
  String get formattedConvertedAmount =>
      Formatters.formatAmount(convertedAmountCents, targetCurrency);

  /// 格式化的匯率
  String get formattedExchangeRate =>
      Formatters.formatExchangeRate(exchangeRate);

  /// 是否有收據圖片
  bool get hasReceipt =>
      receiptImagePath != null && receiptImagePath!.isNotEmpty;

  /// 計算距離永久刪除的天數
  int? get daysUntilPermanentDelete {
    if (!isDeleted || deletedAt == null) return null;
    final deletionDate = deletedAt!.add(const Duration(days: 30));
    return deletionDate.difference(DateTime.now()).inDays;
  }

  /// 從 Map 建立（資料庫讀取）
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      originalAmountCents: map['original_amount'] as int,
      originalCurrency: map['original_currency'] as String,
      exchangeRate: map['exchange_rate'] as int,
      exchangeRateSource: ExchangeRateSourceExtension.fromString(
        map['exchange_rate_source'] as String,
      ),
      convertedAmountCents: map['hkd_amount'] as int,
      targetCurrency: (map['target_currency'] as String?) ??
          CurrencyConstants.defaultPrimaryCurrency,
      description: map['description'] as String,
      category: ExpenseCategoryExtension.fromString(map['category'] as String?),
      receiptImagePath: map['receipt_image_path'] as String?,
      thumbnailPath: map['thumbnail_path'] as String?,
      isDeleted: (map['is_deleted'] as int) == 1,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// 轉換為 Map（資料庫寫入）
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': Formatters.formatDateForStorage(date),
      'original_amount': originalAmountCents,
      'original_currency': originalCurrency,
      'exchange_rate': exchangeRate,
      'exchange_rate_source': exchangeRateSource.value,
      'hkd_amount': convertedAmountCents,
      'target_currency': targetCurrency,
      'description': description,
      'category': category?.name,
      'receipt_image_path': receiptImagePath,
      'thumbnail_path': thumbnailPath,
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt != null
          ? Formatters.formatDateForStorage(deletedAt!)
          : null,
      'created_at': Formatters.formatDateForStorage(createdAt),
      'updated_at': Formatters.formatDateForStorage(updatedAt),
    };
  }

  /// 複製並修改
  ///
  /// 使用 [clearCategory] 來清除分類（設為 null）
  Expense copyWith({
    int? id,
    DateTime? date,
    int? originalAmountCents,
    String? originalCurrency,
    int? exchangeRate,
    ExchangeRateSource? exchangeRateSource,
    int? convertedAmountCents,
    String? targetCurrency,
    String? description,
    ExpenseCategory? category,
    bool clearCategory = false,
    String? receiptImagePath,
    String? thumbnailPath,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      originalAmountCents: originalAmountCents ?? this.originalAmountCents,
      originalCurrency: originalCurrency ?? this.originalCurrency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      exchangeRateSource: exchangeRateSource ?? this.exchangeRateSource,
      convertedAmountCents: convertedAmountCents ?? this.convertedAmountCents,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      description: description ?? this.description,
      category: clearCategory ? null : (category ?? this.category),
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Expense) return false;

    // 如果兩者都有 id，用 id 比較
    if (id != null && other.id != null) {
      return id == other.id;
    }

    // 如果都沒有 id（新建未儲存），比較所有欄位
    if (id == null && other.id == null) {
      return date == other.date &&
          originalAmountCents == other.originalAmountCents &&
          originalCurrency == other.originalCurrency &&
          description == other.description &&
          category == other.category &&
          createdAt == other.createdAt;
    }

    // 一個有 id 一個沒有，不相等
    return false;
  }

  @override
  int get hashCode {
    // 如果有 id，用 id 作為 hashCode
    if (id != null) return id.hashCode;

    // 沒有 id 時，用多欄位組合
    return Object.hash(
      date,
      originalAmountCents,
      originalCurrency,
      description,
      category,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, date: $date, amount: $formattedOriginalAmount, '
        'description: $description, category: $category, isDeleted: $isDeleted)';
  }
}

/// 月份摘要資料
class MonthSummary {
  const MonthSummary({
    required this.year,
    required this.month,
    required this.totalCount,
    required this.totalConvertedAmountCents,
    this.dominantCurrency,
    this.hasMixedCurrencies = false,
  });

  final int year;
  final int month;
  final int totalCount;
  final int totalConvertedAmountCents;

  /// 主要的目標幣種（如果所有支出相同）
  final String? dominantCurrency;

  /// 是否有混合幣種
  final bool hasMixedCurrencies;

  /// 格式化的月份
  /// 根據 locale 自動選擇格式：
  /// - 中文：2025年1月
  /// - 英文：January 2025
  /// - 日文：2025年1月
  /// - 韓文：2025년 1월
  /// - 西班牙文：enero de 2025
  String formattedMonth({String? locale}) {
    return Formatters.formatMonth(DateTime(year, month), locale: locale);
  }

  /// 格式化的總金額（處理混合幣種）
  String get formattedTotalAmount {
    final currency = dominantCurrency ?? CurrencyConstants.defaultPrimaryCurrency;
    final formatted = Formatters.formatAmount(totalConvertedAmountCents, currency);
    if (hasMixedCurrencies) {
      return '≈ $formatted';
    }
    return formatted;
  }

  factory MonthSummary.empty(int year, int month) {
    return MonthSummary(
      year: year,
      month: month,
      totalCount: 0,
      totalConvertedAmountCents: 0,
      dominantCurrency: CurrencyConstants.defaultPrimaryCurrency,
      hasMixedCurrencies: false,
    );
  }
}
