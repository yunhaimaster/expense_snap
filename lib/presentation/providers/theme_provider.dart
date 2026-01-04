import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/di/service_locator.dart';
import '../../core/utils/app_logger.dart';

/// 主題模式
enum AppThemeMode {
  /// 淺色模式
  light,

  /// 深色模式
  dark,

  /// 跟隨系統
  system,
}

/// 主題 Provider
///
/// 管理 App 主題設定：
/// - 主題模式（淺色/深色/系統）
/// - 主題持久化
/// - 減少動畫選項
class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _loadSettings();
  }

  // ============ 狀態 ============

  AppThemeMode _themeMode = AppThemeMode.system;
  bool _reduceMotion = false;
  bool _isLoading = true;

  // ============ Getters ============

  /// 當前主題模式
  AppThemeMode get themeMode => _themeMode;

  /// 是否減少動畫
  bool get reduceMotion => _reduceMotion;

  /// 是否正在載入
  bool get isLoading => _isLoading;

  /// 取得當前 Brightness（考慮系統設定）
  Brightness get brightness {
    switch (_themeMode) {
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
        return Brightness.dark;
      case AppThemeMode.system:
        // 使用 SchedulerBinding 取得系統 brightness
        final platformBrightness =
            SchedulerBinding.instance.platformDispatcher.platformBrightness;
        return platformBrightness;
    }
  }

  /// 是否為深色模式
  bool get isDarkMode => brightness == Brightness.dark;

  /// 取得 ThemeMode（供 MaterialApp 使用）
  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  // ============ 設定 ============

  /// 設定主題模式
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    await _saveThemeMode(mode);
  }

  /// 設定減少動畫
  Future<void> setReduceMotion(bool value) async {
    if (_reduceMotion == value) return;

    _reduceMotion = value;
    notifyListeners();

    await _saveReduceMotion(value);
  }

  /// 切換主題（淺色 <-> 深色）
  Future<void> toggleTheme() async {
    final newMode = isDarkMode ? AppThemeMode.light : AppThemeMode.dark;
    await setThemeMode(newMode);
  }

  // ============ 持久化 ============

  /// 載入設定
  Future<void> _loadSettings() async {
    try {
      final db = sl.databaseHelper;

      // 載入主題模式
      final modeStr = await db.getSetting('theme_mode');
      if (modeStr != null && modeStr.isNotEmpty) {
        _themeMode = _parseThemeMode(modeStr);
      }

      // 載入減少動畫設定
      final reduceMotionStr = await db.getSetting('reduce_motion');
      _reduceMotion = reduceMotionStr == 'true';

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      AppLogger.warning('Failed to load theme settings: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 儲存主題模式
  Future<void> _saveThemeMode(AppThemeMode mode) async {
    try {
      await sl.databaseHelper.setSetting('theme_mode', mode.name);
    } catch (e) {
      AppLogger.warning('Failed to save theme mode: $e');
    }
  }

  /// 儲存減少動畫設定
  Future<void> _saveReduceMotion(bool value) async {
    try {
      await sl.databaseHelper.setSetting('reduce_motion', value.toString());
    } catch (e) {
      AppLogger.warning('Failed to save reduce motion setting: $e');
    }
  }

  /// 解析主題模式
  AppThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }
}
