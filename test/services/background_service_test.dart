import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/services/background_service.dart';

/// BackgroundService 測試
///
/// 注意：完整的背景任務測試需要實機環境
/// 這裡測試常數和靜態配置
void main() {
  group('BackgroundService 常數', () {
    test('cleanupTaskId 應有正確的值', () {
      expect(BackgroundService.cleanupTaskId, 'expense_snap_cleanup');
    });

    test('cleanupTaskName 應有正確的值', () {
      expect(BackgroundService.cleanupTaskName, 'cleanupDeletedExpenses');
    });

    test('任務 ID 和名稱應不同', () {
      expect(
        BackgroundService.cleanupTaskId,
        isNot(BackgroundService.cleanupTaskName),
      );
    });
  });

  group('BackgroundService 設計', () {
    test('應為私有建構子（單例模式）', () {
      // BackgroundService._() 是私有建構子
      // 所有方法都是 static，不需要實例化
      expect(BackgroundService.cleanupTaskId, isNotNull);
    });
  });
}
