import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:expense_snap/l10n/app_localizations.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/data/datasources/local/database_helper.dart';
import 'package:expense_snap/data/models/backup_status.dart';
import 'package:expense_snap/data/repositories/backup_repository.dart';
import 'package:expense_snap/presentation/providers/locale_provider.dart';
import 'package:expense_snap/presentation/providers/settings_provider.dart';
import 'package:expense_snap/presentation/providers/theme_provider.dart';
import 'package:expense_snap/presentation/screens/settings/settings_screen.dart';

@GenerateMocks([DatabaseHelper, BackupRepository])
import 'settings_screen_test.mocks.dart';

void main() {
  late MockDatabaseHelper mockDatabaseHelper;
  late MockBackupRepository mockBackupRepository;

  const testBackupStatus = BackupStatus(
    lastBackupAt: null,
    lastBackupCount: 0,
    lastBackupSizeKb: 0,
    googleEmail: null,
  );

  setUpAll(() {
    // 註冊 dummy values
    provideDummy<Result<void>>(Result.success(null));
    provideDummy<Result<BackupStatus>>(Result.success(testBackupStatus));
    provideDummy<Result<int>>(Result.success(0));
    provideDummy<Result<String?>>(Result.success(null));
  });

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    mockBackupRepository = MockBackupRepository();

    // 預設 stub
    when(mockDatabaseHelper.getSetting(any)).thenAnswer((_) async => null);
    when(mockBackupRepository.getBackupStatus())
        .thenAnswer((_) async => Result.success(testBackupStatus));
    when(mockBackupRepository.tryRestoreGoogleSession())
        .thenAnswer((_) async => Result.success(null));
    when(mockBackupRepository.calculateLocalStorageUsageKb())
        .thenAnswer((_) async => 1024);
    when(mockBackupRepository.cleanupBackupTempFiles())
        .thenAnswer((_) async => Result.success(0));
    when(mockBackupRepository.isGoogleSignedIn())
        .thenAnswer((_) async => false);
  });

  // 設定測試用的螢幕大小（較高以容納所有內容）
  const testScreenSize = Size(400, 1200);

  Widget buildTestWidget(WidgetTester tester) {
    tester.view.physicalSize = testScreenSize;
    tester.view.devicePixelRatio = 1.0;

    final settingsProvider = SettingsProvider(
      databaseHelper: mockDatabaseHelper,
      backupRepository: mockBackupRepository,
    );
    final themeProvider = ThemeProvider();
    final localeProvider = LocaleProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen 基本渲染', () {
    testWidgets('應顯示 AppBar 和標題', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      expect(find.text('設定'), findsOneWidget);
    });

    testWidgets('應顯示個人資料區塊', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('個人資料'), findsOneWidget);
    });

    testWidgets('應顯示外觀區塊', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('外觀'), findsOneWidget);
    });

    testWidgets('應顯示資料管理區塊', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('資料管理'), findsOneWidget);
    });

    testWidgets('應顯示雲端備份區塊', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('雲端備份'), findsOneWidget);
    });
  });

  group('SettingsScreen 個人資料', () {
    testWidgets('應顯示姓名設定項目', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('姓名'), findsOneWidget);
    });
  });

  group('SettingsScreen 外觀設定', () {
    testWidgets('應顯示主題設定項目', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('主題'), findsOneWidget);
    });

    testWidgets('應顯示減少動畫設定項目', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('減少動畫'), findsOneWidget);
    });

    testWidgets('減少動畫應有 Switch 元件', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsOneWidget);
    });
  });

  group('SettingsScreen 資料管理', () {
    testWidgets('應顯示已刪除項目選項', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('已刪除項目'), findsOneWidget);
    });

    testWidgets('應顯示本地儲存使用量', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('本地儲存使用量'), findsOneWidget);
    });

    testWidgets('應顯示清理暫存檔選項', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('清理暫存檔'), findsOneWidget);
    });
  });

  group('SettingsScreen 雲端備份', () {
    testWidgets('未連接時應顯示連接按鈕', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.text('Google 雲端硬碟'), findsOneWidget);
      expect(find.text('連接'), findsOneWidget);
    });
  });

  group('SettingsScreen UI 結構', () {
    testWidgets('應使用 ListView 顯示設定項目', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('應使用 Consumer 監聽 SettingsProvider', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestWidget(tester));
      await tester.pump();

      expect(find.byType(Consumer<SettingsProvider>), findsOneWidget);
    });
  });
}
