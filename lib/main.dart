import 'package:flutter/material.dart';

import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';

/// App 入口點
void main() async {
  // 確保 Flutter binding 初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化服務定位器（依賴注入）
  await _initializeApp();

  runApp(const ExpenseSnapApp());
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

/// App 根元件
class ExpenseSnapApp extends StatelessWidget {
  const ExpenseSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Snap',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const _PlaceholderHomePage(),
    );
  }
}

/// 臨時首頁（Phase 2 會替換）
class _PlaceholderHomePage extends StatelessWidget {
  const _PlaceholderHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Snap'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Phase 1 完成',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              '專案基礎架構已建立',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
