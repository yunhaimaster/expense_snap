import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/utils/app_logger.dart';
import '../../l10n/app_localizations.dart';

/// 語言設定 Provider
///
/// 管理應用程式的語言偏好設定，支援：
/// - 中文 (zh) - 預設
/// - 英文 (en)
/// - 跟隨系統
class LocaleProvider extends ChangeNotifier {
  /// 支援的語言列表
  static const List<Locale> supportedLocales = S.supportedLocales;

  /// 語言代碼對應的顯示名稱
  static const Map<String, String> localeNames = {
    'zh': '繁體中文',
    'en': 'English',
    'system': '跟隨系統',
  };

  Locale? _locale;
  bool _isLoaded = false;

  /// 當前語言設定
  ///
  /// null 表示跟隨系統
  Locale? get locale => _locale;

  /// 是否已載入設定
  bool get isLoaded => _isLoaded;

  /// 當前使用的語言代碼（用於 UI 顯示）
  String get currentLocaleCode => _locale?.languageCode ?? 'system';

  /// 當前語言名稱（用於 UI 顯示）
  String get currentLocaleName => localeNames[currentLocaleCode] ?? currentLocaleCode;

  /// 實際解析後的 Locale（考慮系統設定）
  Locale get resolvedLocale {
    if (_locale != null) {
      return _locale!;
    }
    // 跟隨系統時，使用系統 locale
    final systemLocale = PlatformDispatcher.instance.locale;
    // 檢查系統 locale 是否在支援列表中
    if (supportedLocales.any((l) => l.languageCode == systemLocale.languageCode)) {
      return Locale(systemLocale.languageCode);
    }
    // 不支援的系統語言，使用預設（中文）
    return const Locale('zh');
  }

  /// 初始化，從儲存載入設定
  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      final savedLocale = await sl.databaseHelper.getSetting('app_locale');
      if (savedLocale != null && savedLocale.isNotEmpty && savedLocale != 'system') {
        // 驗證是支援的語言
        if (supportedLocales.any((l) => l.languageCode == savedLocale)) {
          _locale = Locale(savedLocale);
        }
      }
      // savedLocale == null 或 'system' 時，_locale 保持 null（跟隨系統）
    } catch (e) {
      AppLogger.warning('Failed to load locale setting: $e');
    }

    _isLoaded = true;
    notifyListeners();
  }

  /// 設定語言
  ///
  /// [locale] 可為：
  /// - 具體的 Locale（如 Locale('en')）
  /// - null 表示跟隨系統
  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;

    // 驗證是支援的語言
    if (locale != null && !supportedLocales.any((l) => l.languageCode == locale.languageCode)) {
      AppLogger.warning('Unsupported locale: $locale');
      return;
    }

    _locale = locale;
    notifyListeners();

    // 持久化儲存
    try {
      final value = locale?.languageCode ?? 'system';
      await sl.databaseHelper.setSetting('app_locale', value);
      AppLogger.info('Locale saved: $value');
    } catch (e) {
      AppLogger.warning('Failed to save locale setting: $e');
    }
  }

  /// 根據語言代碼設定（方便 UI 使用）
  Future<void> setLocaleByCode(String code) async {
    if (code == 'system') {
      await setLocale(null);
    } else {
      await setLocale(Locale(code));
    }
  }

  /// 是否為選中的語言
  bool isSelected(String code) {
    if (code == 'system') {
      return _locale == null;
    }
    return _locale?.languageCode == code;
  }
}
