import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'data/repositories/exchange_rate_repository.dart';
import 'data/repositories/expense_repository.dart';
import 'domain/repositories/expense_repository.dart';
import 'presentation/providers/connectivity_provider.dart';
import 'presentation/providers/exchange_rate_provider.dart';
import 'presentation/providers/expense_provider.dart';
import 'services/image_service.dart';

/// App 入口點
void main() async {
  // 確保 Flutter binding 初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化服務定位器（依賴注入）
  await _initializeApp();

  // 建立服務實例（在 runApp 之前，確保只建立一次）
  final imageService = ImageService();
  final expenseRepository = ExpenseRepository(
    databaseHelper: sl.databaseHelper,
    imageService: imageService,
  );
  final exchangeRateRepository = ExchangeRateRepository(
    databaseHelper: sl.databaseHelper,
  );

  // 檢查是否需要 onboarding
  final needsOnboarding = await _checkOnboarding();

  runApp(ExpenseSnapApp(
    needsOnboarding: needsOnboarding,
    expenseRepository: expenseRepository,
    imageService: imageService,
    exchangeRateRepository: exchangeRateRepository,
  ));
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

/// App 根元件
class ExpenseSnapApp extends StatelessWidget {
  const ExpenseSnapApp({
    super.key,
    required this.needsOnboarding,
    required this.expenseRepository,
    required this.imageService,
    required this.exchangeRateRepository,
  });

  final bool needsOnboarding;
  final ExpenseRepository expenseRepository;
  final ImageService imageService;
  final ExchangeRateRepository exchangeRateRepository;

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
      ],
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
    );
  }
}
