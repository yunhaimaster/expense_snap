import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/core/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    group('instance', () {
      test('應為單例模式', () {
        // Arrange & Act
        final instance1 = NotificationService.instance;
        final instance2 = NotificationService.instance;

        // Assert
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('常數定義', () {
      test('channelId 應為非空字串', () {
        expect(NotificationService.channelId, isNotEmpty);
      });

      test('channelName 應為非空字串', () {
        expect(NotificationService.channelName, isNotEmpty);
      });

      test('channelDescription 應為非空字串', () {
        expect(NotificationService.channelDescription, isNotEmpty);
      });

      test('monthEndReminderId 應為正整數', () {
        expect(NotificationService.monthEndReminderId, greaterThan(0));
      });

      test('channelId 應符合 Android 頻道 ID 慣例', () {
        // Android channel ID 通常使用 snake_case
        expect(
          NotificationService.channelId,
          matches(RegExp(r'^[a-z][a-z0-9_]*$')),
        );
      });
    });

    group('showNotification', () {
      test('showNotification 方法應存在', () {
        // 驗證方法簽名正確（需要 title 和 body）
        final service = NotificationService.instance;
        expect(service.showNotification, isA<Function>());
      });
    });

    group('requestPermission', () {
      test('requestPermission 方法應存在', () {
        final service = NotificationService.instance;
        expect(service.requestPermission, isA<Function>());
      });
    });

    group('月底提醒', () {
      test('isMonthEndReminderSet 方法應存在', () {
        final service = NotificationService.instance;
        expect(service.isMonthEndReminderSet, isA<Function>());
      });

      test('setMonthEndReminder 方法應存在', () {
        final service = NotificationService.instance;
        expect(service.setMonthEndReminder, isA<Function>());
      });
    });

    // 注意：以下功能需要平台通道，需在整合測試中測試：
    // - initialize() 實際初始化 plugin
    // - requestPermission() 實際請求權限
    // - showNotification() 實際顯示通知
    // - _scheduleMonthEndReminder() 排程通知
    // - _cancelMonthEndReminder() 取消通知
    //
    // FlutterLocalNotificationsPlugin 在測試環境中會拋出
    // LateInitializationError（Error 而非 Exception），
    // 無法在純 unit test 中完整測試。
    // 建議使用 integration_test 搭配 TestWidgetsFlutterBinding 進行完整測試。
  });
}
