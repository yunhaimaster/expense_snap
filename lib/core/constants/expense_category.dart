// ignore_for_file: avoid_dynamic_calls
import 'package:flutter/material.dart';

import '../utils/app_logger.dart';

/// 支出分類
///
/// 預設提供 8 個常用分類，不可自訂
enum ExpenseCategory {
  meals, // 餐飲
  transport, // 交通
  accommodation, // 住宿
  officeSupplies, // 辦公用品
  communication, // 通訊
  entertainment, // 娛樂
  medical, // 醫療
  other, // 其他
}

/// ExpenseCategory 擴展方法
extension ExpenseCategoryExtension on ExpenseCategory {
  /// 取得 i18n key (僅用於存儲或 debug，UI 請用 getLocalizedName)
  String get i18nKey => 'category_$name';

  /// 取得本地化名稱
  ///
  /// 統一分類名稱轉換邏輯，避免 DRY 違反
  /// [l10n] 可以是 S 或 ExportStrings 類型
  String getLocalizedName(dynamic l10n) {
    return switch (this) {
      ExpenseCategory.meals => l10n.category_meals as String,
      ExpenseCategory.transport => l10n.category_transport as String,
      ExpenseCategory.accommodation => l10n.category_accommodation as String,
      ExpenseCategory.officeSupplies => l10n.category_officeSupplies as String,
      ExpenseCategory.communication => l10n.category_communication as String,
      ExpenseCategory.entertainment => l10n.category_entertainment as String,
      ExpenseCategory.medical => l10n.category_medical as String,
      ExpenseCategory.other => l10n.category_other as String,
    };
  }

  /// 取得分類顏色（支援淺色/深色主題）
  Color getColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (this) {
      ExpenseCategory.meals =>
        isDark ? const Color(0xFF81C784) : const Color(0xFF4CAF50),
      ExpenseCategory.transport =>
        isDark ? const Color(0xFF64B5F6) : const Color(0xFF2196F3),
      ExpenseCategory.accommodation =>
        isDark ? const Color(0xFFBA68C8) : const Color(0xFF9C27B0),
      ExpenseCategory.officeSupplies =>
        isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800),
      ExpenseCategory.communication =>
        isDark ? const Color(0xFF4DD0E1) : const Color(0xFF00BCD4),
      ExpenseCategory.entertainment =>
        isDark ? const Color(0xFFE57373) : const Color(0xFFF44336),
      ExpenseCategory.medical =>
        isDark ? const Color(0xFFF06292) : const Color(0xFFE91E63),
      ExpenseCategory.other =>
        isDark ? const Color(0xFF90A4AE) : const Color(0xFF607D8B),
    };
  }

  /// 取得文字顏色（確保對比度）
  ///
  /// 淺色主題背景較深，使用白字
  /// 深色主題背景較亮，使用深色字
  Color getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.black87 : Colors.white;
  }

  /// 從字串解析（帶錯誤日誌）
  ///
  /// - 若 value 為 null，返回 null
  /// - 若 value 為有效分類名稱，返回對應 enum
  /// - 若 value 為無效值，記錄警告並返回 other
  static ExpenseCategory? fromString(String? value) {
    if (value == null) return null;
    // 安全解析：先檢查是否為有效值
    final validNames = ExpenseCategory.values.map((e) => e.name).toSet();
    if (validNames.contains(value)) {
      return ExpenseCategory.values.byName(value);
    }
    // 記錄未知分類值，便於除錯
    AppLogger.warning('Unknown expense category: $value, defaulting to other');
    return ExpenseCategory.other;
  }
}
