import 'package:flutter/material.dart';

import '../../core/services/showcase_service.dart';
import '../../core/utils/app_logger.dart';

/// Showcase 提示狀態管理
///
/// 管理功能發現提示的顯示狀態
class ShowcaseProvider extends ChangeNotifier {
  final _service = ShowcaseService.instance;

  bool _fabShowcaseComplete = true;
  bool _swipeShowcaseComplete = true;
  bool _exportShowcaseComplete = true;
  bool _initialized = false;

  // 是否已 dispose
  bool _disposed = false;

  bool get fabShowcaseComplete => _fabShowcaseComplete;
  bool get swipeShowcaseComplete => _swipeShowcaseComplete;
  bool get exportShowcaseComplete => _exportShowcaseComplete;
  bool get initialized => _initialized;

  /// 應該顯示 FAB 提示
  bool get shouldShowFabShowcase => !_fabShowcaseComplete;

  /// 應該顯示滑動刪除提示（需要有至少一筆支出）
  bool get shouldShowSwipeShowcase => !_swipeShowcaseComplete;

  /// 應該顯示匯出提示（需要有至少 5 筆支出）
  bool get shouldShowExportShowcase => !_exportShowcaseComplete;

  /// 初始化載入狀態
  ///
  /// 使用 Future.wait 並行載入所有狀態以提升效能
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 並行載入所有 showcase 狀態
      final results = await Future.wait([
        _service.isShowcaseComplete(ShowcaseService.fabShowcase),
        _service.isShowcaseComplete(ShowcaseService.swipeDeleteShowcase),
        _service.isShowcaseComplete(ShowcaseService.exportShowcase),
      ]);

      // 檢查是否已 dispose，避免在異步操作後更新已銷毀的 provider
      if (_disposed) return;

      _fabShowcaseComplete = results[0];
      _swipeShowcaseComplete = results[1];
      _exportShowcaseComplete = results[2];

      _initialized = true;
      _safeNotifyListeners();
    } catch (e) {
      AppLogger.warning('Failed to initialize showcase state: $e');
    }
  }

  /// 標記 FAB 提示完成
  Future<void> completeFabShowcase() async {
    if (_fabShowcaseComplete) return;

    try {
      await _service.markShowcaseComplete(ShowcaseService.fabShowcase);
      if (_disposed) return;
      _fabShowcaseComplete = true;
      _safeNotifyListeners();
    } catch (e) {
      AppLogger.warning('Failed to complete FAB showcase: $e');
    }
  }

  /// 標記滑動刪除提示完成
  Future<void> completeSwipeShowcase() async {
    if (_swipeShowcaseComplete) return;

    try {
      await _service.markShowcaseComplete(ShowcaseService.swipeDeleteShowcase);
      if (_disposed) return;
      _swipeShowcaseComplete = true;
      _safeNotifyListeners();
    } catch (e) {
      AppLogger.warning('Failed to complete swipe showcase: $e');
    }
  }

  /// 標記匯出提示完成
  Future<void> completeExportShowcase() async {
    if (_exportShowcaseComplete) return;

    try {
      await _service.markShowcaseComplete(ShowcaseService.exportShowcase);
      if (_disposed) return;
      _exportShowcaseComplete = true;
      _safeNotifyListeners();
    } catch (e) {
      AppLogger.warning('Failed to complete export showcase: $e');
    }
  }

  /// 檢查是否應顯示匯出提示（5 筆以上支出）
  Future<bool> checkExportShowcaseReady() async {
    if (_exportShowcaseComplete) return false;

    try {
      final count = await _service.getExpenseCount();
      return count >= 5;
    } catch (e) {
      AppLogger.warning('Failed to check export showcase ready: $e');
      return false;
    }
  }

  /// 重置所有提示（開發用）
  Future<void> resetAll() async {
    try {
      await _service.resetAllShowcases();
      if (_disposed) return;
      _fabShowcaseComplete = false;
      _swipeShowcaseComplete = false;
      _exportShowcaseComplete = false;
      _safeNotifyListeners();
    } catch (e) {
      AppLogger.warning('Failed to reset showcases: $e');
    }
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
    AppLogger.debug('ShowcaseProvider disposed');
    super.dispose();
  }
}
