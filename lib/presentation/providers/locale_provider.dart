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
    'zh_Hans': '简体中文',
    'en': 'English',
    'ja': '日本語',
    'ko': '한국어',
    'es': 'Español',
    'system': '跟隨系統',
  };

  Locale? _locale;
  bool _isLoaded = false;

  // 是否已 dispose
  bool _disposed = false;

  /// 當前語言設定
  ///
  /// null 表示跟隨系統
  Locale? get locale => _locale;

  /// 是否已載入設定
  bool get isLoaded => _isLoaded;

  /// 當前使用的語言代碼（用於 UI 顯示）
  String get currentLocaleCode {
    if (_locale == null) return 'system';
    // 簡體中文使用 scriptCode 區分
    if (_locale!.scriptCode == 'Hans') return 'zh_Hans';
    return _locale!.languageCode;
  }

  /// 當前語言名稱（用於 UI 顯示）
  String get currentLocaleName =>
      localeNames[currentLocaleCode] ?? currentLocaleCode;

  /// 實際解析後的 Locale（考慮系統設定）
  Locale get resolvedLocale {
    if (_locale != null) {
      return _locale!;
    }
    // 跟隨系統時，使用系統 locale
    final systemLocale = PlatformDispatcher.instance.locale;

    // 優先精確匹配（包含 scriptCode，如 zh_Hans）
    final exactMatch = supportedLocales.cast<Locale?>().firstWhere(
      (l) =>
          l!.languageCode == systemLocale.languageCode &&
          l.scriptCode == systemLocale.scriptCode,
      orElse: () => null,
    );
    if (exactMatch != null) {
      return exactMatch;
    }

    // 次要匹配：僅 languageCode
    final languageMatch = supportedLocales.cast<Locale?>().firstWhere(
      (l) => l!.languageCode == systemLocale.languageCode,
      orElse: () => null,
    );
    if (languageMatch != null) {
      return languageMatch;
    }

    // 不支援的系統語言，使用預設（繁體中文）
    return const Locale('zh');
  }

  /// 初始化，從儲存載入設定
  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      final savedLocale = await sl.databaseHelper.getSetting('app_locale');
      if (savedLocale != null &&
          savedLocale.isNotEmpty &&
          savedLocale != 'system') {
        // 簡體中文特殊處理
        if (savedLocale == 'zh_Hans') {
          _locale = const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hans',
          );
        } else if (supportedLocales.any(
          (l) => l.languageCode == savedLocale,
        )) {
          // 驗證是支援的語言
          _locale = Locale(savedLocale);
        }
      }
      // savedLocale == null 或 'system' 時，_locale 保持 null（跟隨系統）
    } on Object catch (e) {
      // StateError 可能在 sl 未初始化時拋出（非 Exception）
      AppLogger.warning('Failed to load locale setting: $e');
    }

    _isLoaded = true;
    _safeNotifyListeners();
  }

  /// 設定語言
  ///
  /// [locale] 可為：
  /// - 具體的 Locale（如 Locale('en')）
  /// - null 表示跟隨系統
  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;

    // 驗證是支援的語言（需精確匹配 languageCode 和 scriptCode）
    if (locale != null) {
      final isSupported = supportedLocales.any(
        (l) =>
            l.languageCode == locale.languageCode &&
            l.scriptCode == locale.scriptCode,
      );
      if (!isSupported) {
        AppLogger.warning('Unsupported locale: $locale');
        return;
      }
    }

    _locale = locale;
    _safeNotifyListeners();

    // 持久化儲存
    try {
      String value;
      if (locale == null) {
        value = 'system';
      } else if (locale.scriptCode == 'Hans') {
        value = 'zh_Hans';
      } else {
        value = locale.languageCode;
      }
      await sl.databaseHelper.setSetting('app_locale', value);
      AppLogger.info('Locale saved: $value');
    } on Object catch (e) {
      AppLogger.warning('Failed to save locale setting: $e');
    }
  }

  /// 根據語言代碼設定（方便 UI 使用）
  Future<void> setLocaleByCode(String code) async {
    if (code == 'system') {
      await setLocale(null);
    } else if (code == 'zh_Hans') {
      // 簡體中文使用 scriptCode
      await setLocale(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      );
    } else {
      await setLocale(Locale(code));
    }
  }

  /// 是否為選中的語言
  bool isSelected(String code) {
    if (code == 'system') {
      return _locale == null;
    }
    if (code == 'zh_Hans') {
      return _locale?.scriptCode == 'Hans';
    }
    return _locale?.languageCode == code && _locale?.scriptCode == null;
  }

  /// 安全的 notifyListeners（防止 dispose 後呼叫）
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    AppLogger.debug('LocaleProvider disposed');
    super.dispose();
  }
}
