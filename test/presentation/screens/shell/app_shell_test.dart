import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:expense_snap/l10n/app_localizations.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/data/datasources/local/database_helper.dart';
import 'package:expense_snap/data/models/backup_status.dart';
import 'package:expense_snap/data/models/expense.dart';
import 'package:expense_snap/data/repositories/backup_repository.dart';
import 'package:expense_snap/domain/repositories/expense_repository.dart';
import 'package:expense_snap/presentation/providers/backup_provider.dart';
import 'package:expense_snap/presentation/providers/connectivity_provider.dart';
import 'package:expense_snap/presentation/providers/expense_provider.dart';
import 'package:expense_snap/presentation/providers/google_auth_provider.dart';
import 'package:expense_snap/presentation/providers/locale_provider.dart';
import 'package:expense_snap/presentation/providers/settings_provider.dart';
import 'package:expense_snap/presentation/providers/showcase_provider.dart';
import 'package:expense_snap/presentation/providers/theme_provider.dart';
import 'package:expense_snap/presentation/screens/shell/app_shell.dart';
import 'package:expense_snap/services/image_service.dart';

@GenerateMocks([
  IExpenseRepository,
  ImageService,
  DatabaseHelper,
  BackupRepository,
])
import 'app_shell_test.mocks.dart';

void main() {
  late MockIExpenseRepository mockExpenseRepository;
  late MockImageService mockImageService;
  late MockDatabaseHelper mockDatabaseHelper;
  late MockBackupRepository mockBackupRepository;

  const testBackupStatus = BackupStatus(
    lastBackupAt: null,
    lastBackupCount: 0,
    lastBackupSizeKb: 0,
    googleEmail: null,
  );

  final testSummary = MonthSummary(
    year: DateTime.now().year,
    month: DateTime.now().month,
    totalConvertedAmountCents: 0,
    totalCount: 0,
  );

  setUpAll(() {
    // 註冊 dummy values
    provideDummy<Result<List<Expense>>>(Result.success(<Expense>[]));
    provideDummy<Result<MonthSummary>>(Result.success(testSummary));
    provideDummy<Result<void>>(Result.success(null));
    provideDummy<Result<BackupStatus>>(Result.success(testBackupStatus));
    provideDummy<Result<int>>(Result.success(0));
    provideDummy<Result<String?>>(Result.success(null));
    provideDummy<Result<String>>(Result.success(''));
  });

  setUp(() {
    mockExpenseRepository = MockIExpenseRepository();
    mockImageService = MockImageService();
    mockDatabaseHelper = MockDatabaseHelper();
    mockBackupRepository = MockBackupRepository();

    // ExpenseProvider stubs
    when(
      mockExpenseRepository.getExpensesByMonth(
        year: anyNamed('year'),
        month: anyNamed('month'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      ),
    ).thenAnswer((_) async => Result.success(<Expense>[]));

    when(
      mockExpenseRepository.getMonthSummary(
        year: anyNamed('year'),
        month: anyNamed('month'),
      ),
    ).thenAnswer((_) async => Result.success(testSummary));

    // SettingsProvider stubs
    when(mockDatabaseHelper.getSetting(any)).thenAnswer((_) async => null);

    // BackupProvider stubs
    when(
      mockBackupRepository.getBackupStatus(),
    ).thenAnswer((_) async => Result.success(testBackupStatus));
    when(
      mockBackupRepository.tryRestoreGoogleSession(),
    ).thenAnswer((_) async => Result.success(null));
    when(
      mockBackupRepository.calculateLocalStorageUsageKb(),
    ).thenAnswer((_) async => 1024);
    when(
      mockBackupRepository.cleanupBackupTempFiles(),
    ).thenAnswer((_) async => Result.success(0));
    when(
      mockBackupRepository.isGoogleSignedIn(),
    ).thenAnswer((_) async => false);
  });

  // 較大的螢幕以容納所有子畫面
  const testScreenSize = Size(400, 900);

  Widget buildTestWidget(WidgetTester tester) {
    tester.view.physicalSize = testScreenSize;
    tester.view.devicePixelRatio = 1.0;

    final expenseProvider = ExpenseProvider(
      repository: mockExpenseRepository,
      imageService: mockImageService,
    );
    final settingsProvider = SettingsProvider(
      databaseHelper: mockDatabaseHelper,
    );
    final themeProvider = ThemeProvider();
    final localeProvider = LocaleProvider();
    final googleAuthProvider = GoogleAuthProvider(
      backupRepository: mockBackupRepository,
    );
    final backupProvider = BackupProvider(
      backupRepository: mockBackupRepository,
      googleAuthProvider: googleAuthProvider,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<GoogleAuthProvider>.value(
          value: googleAuthProvider,
        ),
        ChangeNotifierProvider<BackupProvider>.value(value: backupProvider),
        ChangeNotifierProvider<ShowcaseProvider>(
          create: (_) => ShowcaseProvider(),
        ),
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(),
        ),
        Provider<IExpenseRepository>.value(value: mockExpenseRepository),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: AppShell(),
      ),
    );
  }

  group('AppShell 基本渲染', () {
    testWidgets('應顯示 BottomNavigationBar', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('應顯示三個導航項目', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      // 首頁、匯出、設定
      expect(find.text('首頁'), findsOneWidget);
      expect(find.text('匯出'), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);
    });

    testWidgets('應使用 IndexedStack 保持子畫面狀態', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      expect(find.byType(IndexedStack), findsOneWidget);
    });
  });

  group('AppShell 初始 Tab', () {
    testWidgets('預設應選中首頁 Tab', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      // BottomNavigationBar 的 currentIndex 應為 0
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, equals(0));
    });
  });

  group('AppShell Tab 切換', () {
    testWidgets('點擊匯出 Tab 應切換到匯出畫面', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      // 點擊匯出 Tab
      await tester.tap(find.text('匯出'));
      await tester.pump();

      // 驗證 currentIndex 已變更
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, equals(1));
    });

    testWidgets('點擊設定 Tab 應切換到設定畫面', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      // 點擊設定 Tab
      await tester.tap(find.text('設定'));
      await tester.pump();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, equals(2));
    });

    testWidgets('從設定切回首頁應正常運作', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      // 切到設定
      await tester.tap(find.text('設定'));
      await tester.pump();

      // 切回首頁
      await tester.tap(find.text('首頁'));
      await tester.pump();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, equals(0));
    });
  });

  group('AppShell 導航圖標', () {
    testWidgets('應顯示首頁圖標', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      // 首頁選中時用 filled icon
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('應顯示匯出圖標', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      // 匯出未選中用 outlined icon
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
    });

    testWidgets('應顯示設定圖標', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      // 設定未選中用 outlined icon
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });
  });
}
