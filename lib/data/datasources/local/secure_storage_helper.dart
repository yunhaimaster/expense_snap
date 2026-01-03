import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/utils/app_logger.dart';

/// 安全儲存助手 - 用於儲存 OAuth tokens 等敏感資料
class SecureStorageHelper {
  SecureStorageHelper._();

  static final SecureStorageHelper instance = SecureStorageHelper._();

  // Android 設定：加密選項
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  // 儲存鍵值常數
  static const String _keyGoogleAccessToken = 'google_access_token';
  static const String _keyGoogleRefreshToken = 'google_refresh_token';
  static const String _keyGoogleTokenExpiry = 'google_token_expiry';

  // ============ Google OAuth Tokens ============

  /// 儲存 Google Access Token
  Future<void> saveGoogleAccessToken(String token) async {
    await _storage.write(key: _keyGoogleAccessToken, value: token);
    AppLogger.info('Google access token saved', tag: 'SecureStorage');
  }

  /// 取得 Google Access Token
  Future<String?> getGoogleAccessToken() async {
    return await _storage.read(key: _keyGoogleAccessToken);
  }

  /// 儲存 Google Refresh Token
  Future<void> saveGoogleRefreshToken(String token) async {
    await _storage.write(key: _keyGoogleRefreshToken, value: token);
    AppLogger.info('Google refresh token saved', tag: 'SecureStorage');
  }

  /// 取得 Google Refresh Token
  Future<String?> getGoogleRefreshToken() async {
    return await _storage.read(key: _keyGoogleRefreshToken);
  }

  /// 儲存 Token 過期時間
  Future<void> saveGoogleTokenExpiry(DateTime expiry) async {
    await _storage.write(
      key: _keyGoogleTokenExpiry,
      value: expiry.toIso8601String(),
    );
  }

  /// 取得 Token 過期時間
  Future<DateTime?> getGoogleTokenExpiry() async {
    final value = await _storage.read(key: _keyGoogleTokenExpiry);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// 檢查 Access Token 是否過期
  Future<bool> isGoogleTokenExpired() async {
    final expiry = await getGoogleTokenExpiry();
    if (expiry == null) return true;

    // 提前 5 分鐘視為過期，預留刷新時間
    return DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)));
  }

  /// 清除所有 Google 相關 tokens
  Future<void> clearGoogleTokens() async {
    await Future.wait([
      _storage.delete(key: _keyGoogleAccessToken),
      _storage.delete(key: _keyGoogleRefreshToken),
      _storage.delete(key: _keyGoogleTokenExpiry),
    ]);
    AppLogger.info('Google tokens cleared', tag: 'SecureStorage');
  }

  // ============ 通用方法 ============

  /// 儲存任意值
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// 讀取任意值
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// 刪除任意值
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// 檢查鍵是否存在
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// 清除所有儲存的資料
  Future<void> deleteAll() async {
    await _storage.deleteAll();
    AppLogger.warning('All secure storage data cleared', tag: 'SecureStorage');
  }
}
