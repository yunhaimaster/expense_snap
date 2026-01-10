import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';

/// 網絡連線狀態 Provider
///
/// 使用 connectivity_plus 監聽網絡狀態變化
class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// 當前是否有網絡連線
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// 當前是否為離線狀態
  bool get isOffline => !_isConnected;

  /// 當前連線類型
  List<ConnectivityResult> _connectionTypes = [];
  List<ConnectivityResult> get connectionTypes => _connectionTypes;

  /// 是否使用 WiFi
  bool get isWifi => _connectionTypes.contains(ConnectivityResult.wifi);

  /// 是否使用行動網絡
  bool get isMobile => _connectionTypes.contains(ConnectivityResult.mobile);

  /// 初始化
  Future<void> _init() async {
    // 取得初始狀態
    try {
      _connectionTypes = await _connectivity.checkConnectivity();
      _updateConnectionStatus(_connectionTypes);
    } on Exception catch (e) {
      AppLogger.error('Failed to check initial connectivity', error: e);
    }

    // 監聽狀態變化
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (e) {
        AppLogger.error('Connectivity stream error', error: e);
      },
    );
  }

  /// 更新連線狀態
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    _connectionTypes = results;

    final wasConnected = _isConnected;
    _isConnected = !results.contains(ConnectivityResult.none);

    if (wasConnected != _isConnected) {
      AppLogger.info(
        'Connectivity changed: ${_isConnected ? 'Online' : 'Offline'}',
      );
      notifyListeners();
    }
  }

  /// 手動檢查連線狀態
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      return _isConnected;
    } on Exception catch (e) {
      AppLogger.error('Failed to check connectivity', error: e);
      return _isConnected;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
