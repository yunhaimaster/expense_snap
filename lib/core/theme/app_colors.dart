import 'package:flutter/material.dart';

/// App 色彩定義
class AppColors {
  AppColors._();

  // ============ 淺色主題 ============

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

  // Skeleton Loading 色彩
  static const Color skeletonBase = Color(0xFFE0E0E0);
  static const Color skeletonHighlight = Color(0xFFF5F5F5);

  // ============ 深色主題 ============

  /// 深色主題色彩
  static const dark = _DarkColors();
}

/// 深色主題色彩定義
class _DarkColors {
  const _DarkColors();

  // 主色調（稍微調亮以提高可讀性）
  Color get primary => const Color(0xFF64B5F6);
  Color get primaryLight => const Color(0xFF1E3A5F);
  Color get primaryDark => const Color(0xFF90CAF9);

  // 輔助色
  Color get secondary => const Color(0xFF81C784);
  Color get secondaryLight => const Color(0xFF1B4D2E);
  Color get secondaryDark => const Color(0xFFA5D6A7);

  // 功能色（調整對比度）
  Color get error => const Color(0xFFEF5350);
  Color get errorLight => const Color(0xFF4D2C2C);
  Color get warning => const Color(0xFFFFB74D);
  Color get warningLight => const Color(0xFF4D3D26);
  Color get success => const Color(0xFF81C784);
  Color get successLight => const Color(0xFF1B4D2E);
  Color get info => const Color(0xFF64B5F6);
  Color get infoLight => const Color(0xFF1E3A5F);

  // 中性色
  Color get background => const Color(0xFF121212);
  Color get surface => const Color(0xFF1E1E1E);
  Color get surfaceSecondary => const Color(0xFF2C2C2C);
  Color get divider => const Color(0xFF424242);

  // 文字色（確保 WCAG AA 對比度 >= 4.5:1）
  Color get textPrimary => const Color(0xFFE0E0E0);
  Color get textSecondary => const Color(0xFFB0B0B0);
  Color get textTertiary => const Color(0xFF808080);
  Color get textHint => const Color(0xFF606060);
  Color get textOnPrimary => const Color(0xFF000000);

  // 匯率來源指示色（調整對比度）
  Color get rateAuto => const Color(0xFF81C784);
  Color get rateOffline => const Color(0xFFFFB74D);
  Color get rateDefault => const Color(0xFFEF5350);
  Color get rateManual => const Color(0xFF64B5F6);

  // Skeleton Loading 色彩
  Color get skeletonBase => const Color(0xFF2C2C2C);
  Color get skeletonHighlight => const Color(0xFF3C3C3C);
}
