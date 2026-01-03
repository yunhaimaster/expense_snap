import 'package:flutter/material.dart';

/// App 色彩定義
class AppColors {
  AppColors._();

  // 主色調
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryLight = Color(0xFFBBDEFB);
  static const Color primaryDark = Color(0xFF1976D2);

  // 輔助色
  static const Color secondary = Color(0xFF4CAF50);
  static const Color secondaryLight = Color(0xFFC8E6C9);
  static const Color secondaryDark = Color(0xFF388E3C);

  // 功能色
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFCDD2);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFE0B2);
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFBBDEFB);

  // 中性色
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFFAFAFA);
  static const Color divider = Color(0xFFE0E0E0);

  // 文字色
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // 匯率來源指示色
  static const Color rateAuto = Color(0xFF4CAF50); // 綠色 - 即時
  static const Color rateOffline = Color(0xFFFF9800); // 黃色 - 離線快取
  static const Color rateDefault = Color(0xFFF44336); // 紅色 - 預設
  static const Color rateManual = Color(0xFF2196F3); // 藍色 - 手動

  // 幣種色彩
  static const Map<String, Color> currencyColors = {
    'HKD': Color(0xFFE91E63),
    'CNY': Color(0xFFFF5722),
    'USD': Color(0xFF4CAF50),
  };
}
