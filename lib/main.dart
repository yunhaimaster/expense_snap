import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'data/repositories/backup_repository.dart';
import 'data/repositories/exchange_rate_repository.dart';
import 'data/repositories/expense_repository.dart';
import 'domain/repositories/expense_repository.dart';
import 'presentation/providers/connectivity_provider.dart';
import 'presentation/providers/exchange_rate_provider.dart';
import 'presentation/providers/expense_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/widgets/common/error_boundary.dart';
import 'services/background_service.dart';
import 'services/image_service.dart';

/// App 入口點
void main() async {
  // 在 zone 中執行，捕獲所有未處理的異步錯誤
  await runZonedGuarded(() async {
    // 確保 Flutter binding 初始化
    WidgetsFlutterBinding.ensureInitialized();

    // 設置 Flutter 錯誤處理
    FlutterError.onError = (details) {
      AppLogger.error(
        'Flutter error',
        error: details.exception,
        stackTrace: details.stack,
      );
      // Debug 模式下顯示錯誤，Release 模式下靜默處理
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // 初始化服務定位器（依賴注入）
    await _initializeApp();

    // 初始化背景任務
    await _initializeWorkManager();

    // 建立服務實例（在 runApp 之前，確保只建立一次）
    final imageService = ImageService();
    final expenseRepository = ExpenseRepository(
      databaseHelper: sl.databaseHelper,
      imageService: imageService,
    );
    final exchangeRateRepository = ExchangeRateRepository(
      databaseHelper: sl.databaseHelper,
    );
    final backupRepository = BackupRepository(
      databaseHelper: sl.databaseHelper,
    );

    // 檢查是否需要 onboarding
    final needsOnboarding = await _checkOnboarding();

    // 啟動時執行清理（如果距離上次清理超過 7 天）
    await _performStartupCleanup(expenseRepository, imageService);

    runApp(ExpenseSnapApp(
      needsOnboarding: needsOnboarding,
      expenseRepository: expenseRepository,
      imageService: imageService,
      exchangeRateRepository: exchangeRateRepository,
      backupRepository: backupRepository,
    ));
  }, (error, stackTrace) {
    // 捕獲所有未處理的異步錯誤
    AppLogger.error(
      'Uncaught async error',
      error: error,
      stackTrace: stackTrace,
    );
  });
}

/// 初始化應用程式
Future<void> _initializeApp() async {
  AppLogger.info('Starting app initialization...');

  try {
    // 初始化依賴注入
    await ServiceLocator.instance.initialize();
    AppLogger.info('App initialization completed');
  } catch (e, stackTrace) {
    AppLogger.error(
      'App initialization failed',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

/// 檢查是否完成 onboarding
Future<bool> _checkOnboarding() async {
  try {
    // 使用 ServiceLocator 保持一致性
    final db = sl.databaseHelper;
    final completed = await db.getSetting('onboarding_completed');
    // 空字串或 null 都視為未完成
    return completed != 'true';
  } catch (e) {
    AppLogger.warning('Failed to check onboarding status: $e');
    return true;
  }
}

/// 初始化 WorkManager 背景任務
Future<void> _initializeWorkManager() async {
  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // 註冊每週清理任務
    await Workmanager().registerPeriodicTask(
      BackgroundService.cleanupTaskId,
      BackgroundService.cleanupTaskName,
      frequency: const Duration(days: 7),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );

    AppLogger.info('WorkManager initialized');
  } catch (e) {
    AppLogger.warning('Failed to initialize WorkManager: $e');
  }
}

/// 啟動時執行清理（如果距離上次清理超過 7 天）
Future<void> _performStartupCleanup(
  ExpenseRepository repository,
  ImageService imageService,
) async {
  try {
    final db = sl.databaseHelper;
    final lastCleanupStr = await db.getSetting('last_cleanup_at');

    DateTime? lastCleanup;
    if (lastCleanupStr != null && lastCleanupStr.isNotEmpty) {
      lastCleanup = DateTime.tryParse(lastCleanupStr);
    }

    final now = DateTime.now();
    final shouldCleanup = lastCleanup == null ||
        now.difference(lastCleanup).inDays >= 7;

    if (shouldCleanup) {
      AppLogger.info('Performing startup cleanup...');

      // 清理已刪除超過 30 天的支出
      final cleanupResult = await repository.cleanupExpiredDeletedExpenses();
      cleanupResult.fold(
        onFailure: (e) => AppLogger.warning('Cleanup failed: ${e.message}'),
        onSuccess: (count) => AppLogger.info('Cleaned up $count expenses'),
      );

      // 清理匯出臨時檔案
      await imageService.cleanupTempFiles();

      // 記錄清理時間
      await db.setSetting('last_cleanup_at', now.toIso8601String());
    }
  } catch (e) {
    AppLogger.warning('Startup cleanup failed: $e');
  }
}

/// App 根元件
class ExpenseSnapApp extends StatelessWidget {
  const ExpenseSnapApp({
    super.key,
    required this.needsOnboarding,
    required this.expenseRepository,
    required this.imageService,
    required this.exchangeRateRepository,
    required this.backupRepository,
  });

  final bool needsOnboarding;
  final ExpenseRepository expenseRepository;
  final ImageService imageService;
  final ExchangeRateRepository exchangeRateRepository;
  final BackupRepository backupRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repository 層（使用 .value 因為生命週期由 main() 管理）
        Provider<IExpenseRepository>.value(value: expenseRepository),
        Provider<ImageService>.value(value: imageService),
        Provider<ExchangeRateRepository>.value(value: exchangeRateRepository),

        // Provider 層（State Management）
        ChangeNotifierProvider<ExpenseProvider>(
          create: (_) => ExpenseProvider(
            repository: expenseRepository,
            imageService: imageService,
          ),
        ),
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(),
        ),
        ChangeNotifierProvider<ExchangeRateProvider>(
          create: (_) => ExchangeRateProvider(
            repository: exchangeRateRepository,
          ),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(
            databaseHelper: sl.databaseHelper,
            backupRepository: backupRepository,
          ),
        ),
      ],
      child: ErrorBoundary(
        onError: (error, stackTrace) {
          AppLogger.error('Global error caught', error: error, stackTrace: stackTrace);
        },
        child: MaterialApp(
          title: 'Expense Snap',
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          initialRoute: needsOnboarding ? AppRouter.onboarding : AppRouter.home,
          onGenerateRoute: AppRouter.generateRoute,
          // 支援繁體中文日期選擇器
          locale: const Locale('zh', 'TW'),
          supportedLocales: const [
            Locale('zh', 'TW'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
  }
}
