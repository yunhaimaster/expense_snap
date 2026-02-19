import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/currency_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../data/datasources/local/database_helper.dart';

// 重新匯出以維持向後相容（BackupOperationState 已移至 backup_provider.dart）
export 'backup_provider.dart' show BackupOperationState;

/// 設定 Provider
///
/// 管理使用者偏好設定：
/// - 使用者名稱
/// - 主要幣種
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required DatabaseHelper databaseHelper,
  }) : _db = databaseHelper;

  final DatabaseHelper _db;

  bool _disposed = false;

  // ============ 狀態 ============

  bool _isLoading = true;
  String _userName = AppConstants.defaultUserName;
  String _primaryCurrency = CurrencyConstants.defaultPrimaryCurrency;

  // ============ Getters ============

  bool get isLoading => _isLoading;
  String get userName => _userName;
  String get primaryCurrency => _primaryCurrency;

  // ============ 生命週期 ============

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// 安全的 notifyListeners（防止 dispose 後呼叫）
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // ============ 初始化 ============

  /// 載入所有設定
  Future<void> loadSettings() async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      // 載入使用者名稱
      final name = await _db.getSetting('user_name');
      _userName = name ?? AppConstants.defaultUserName;

      // 載入主要幣種
      final currency = await _db.getSetting('primary_currency');
      _primaryCurrency = currency ?? CurrencyConstants.defaultPrimaryCurrency;

      _isLoading = false;
      _safeNotifyListeners();
    } on Exception catch (e) {
      AppLogger.error('loadSettings failed', error: e, tag: 'Settings');
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // ============ 使用者設定 ============

  /// 更新使用者名稱
  Future<bool> updateUserName(String newName) async {
    if (newName.isEmpty) return false;

    try {
      await _db.setSetting('user_name', newName);
      _userName = newName;
      _safeNotifyListeners();
      return true;
    } on Exception catch (e) {
      AppLogger.error('updateUserName failed', error: e, tag: 'Settings');
      return false;
    }
  }

  /// 更新主要幣種
  Future<bool> updatePrimaryCurrency(String currency) async {
    // 驗證幣種是否有效
    if (!CurrencyConstants.primaryCurrencies.contains(currency)) {
      return false;
    }

    try {
      await _db.setSetting('primary_currency', currency);
      _primaryCurrency = currency;
      _safeNotifyListeners();
      return true;
    } on Exception catch (e) {
      AppLogger.error(
        'updatePrimaryCurrency failed',
        error: e,
        tag: 'Settings',
      );
      return false;
    }
  }
}
