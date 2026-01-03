import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../../data/datasources/local/database_helper.dart';
import '../utils/app_logger.dart';

/// 本地通知服務
///
/// 處理月底匯出提醒等本地通知
class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Completer<void>? _initializationCompleter;

  /// 通知頻道
  static const String channelId = 'expense_snap_reminders';
  static const String channelName = '報銷提醒';
  static const String channelDescription = '月底匯出報銷單提醒';

  /// 通知 ID
  static const int monthEndReminderId = 1;

  /// 初始化通知服務
  ///
  /// 使用 Completer 防止並發初始化導致的競態條件
  Future<void> initialize() async {
    // 如果已經初始化完成，直接返回
    if (_initialized) return;

    // 如果正在初始化中，等待完成
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    // 建立新的 Completer 並開始初始化
    _initializationCompleter = Completer<void>();

    try {
      // 初始化時區
      tz_data.initializeTimeZones();

      // Android 設定
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 設定
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      _initializationCompleter!.complete();
      AppLogger.info('NotificationService initialized');
    } catch (e, stackTrace) {
      _initializationCompleter!.completeError(e, stackTrace);
      _initializationCompleter = null; // 允許重試
      AppLogger.error(
        'Failed to initialize NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 請求通知權限
  Future<bool> requestPermission() async {
    try {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }

      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return false;
    } catch (e) {
      AppLogger.warning('Failed to request notification permission: $e');
      return false;
    }
  }

  /// 檢查是否已設定月底提醒
  Future<bool> isMonthEndReminderSet() async {
    final db = DatabaseHelper.instance;
    final value = await db.getSetting('month_end_reminder_enabled');
    return value == 'true';
  }

  /// 設定月底提醒狀態
  Future<void> setMonthEndReminder(bool enabled) async {
    final db = DatabaseHelper.instance;
    await db.setSetting('month_end_reminder_enabled', enabled ? 'true' : 'false');

    if (enabled) {
      await _scheduleMonthEndReminder();
    } else {
      await _cancelMonthEndReminder();
    }
  }

  /// 排程月底提醒
  Future<void> _scheduleMonthEndReminder() async {
    if (!_initialized) await initialize();

    try {
      final now = DateTime.now();
      // 計算本月最後一天
      final lastDay = DateTime(now.year, now.month + 1, 0);
      // 提前 2 天提醒，上午 10 點
      final reminderDate = DateTime(
        lastDay.year,
        lastDay.month,
        lastDay.day - 2,
        10,
        0,
      );

      // 如果已過提醒時間，排程下個月
      DateTime scheduledDate;
      if (reminderDate.isAfter(now)) {
        scheduledDate = reminderDate;
      } else {
        // 計算下個月的最後一天，並提前 2 日曆天
        final nextMonthLastDay = DateTime(now.year, now.month + 2, 0);
        scheduledDate = DateTime(
          nextMonthLastDay.year,
          nextMonthLastDay.month,
          nextMonthLastDay.day - 2,
          10, // 上午 10 點
          0,
        );
      }

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        monthEndReminderId,
        '月底報銷提醒',
        '本月即將結束，記得匯出報銷單！',
        _toTZDateTime(scheduledDate),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );

      AppLogger.info('Month-end reminder scheduled for $scheduledDate');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to schedule month-end reminder',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 取消月底提醒
  Future<void> _cancelMonthEndReminder() async {
    try {
      await _notifications.cancel(monthEndReminderId);
      AppLogger.info('Month-end reminder cancelled');
    } catch (e) {
      AppLogger.warning('Failed to cancel month-end reminder: $e');
    }
  }

  /// 顯示即時通知
  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (!_initialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details);
    } catch (e) {
      AppLogger.warning('Failed to show notification: $e');
    }
  }

  /// 通知點擊處理
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info('Notification tapped: ${response.id}');
    // 可以在這裡處理導航到匯出頁面
  }

  /// 轉換為 TZDateTime
  tz.TZDateTime _toTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.local(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
    );
  }
}
