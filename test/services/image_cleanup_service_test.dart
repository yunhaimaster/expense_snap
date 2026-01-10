import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite/sqflite.dart';

import 'package:expense_snap/core/utils/path_validator.dart';
import 'package:expense_snap/data/datasources/local/database_helper.dart';
import 'package:expense_snap/services/image_cleanup_service.dart';

@GenerateMocks([DatabaseHelper, Database])
import 'image_cleanup_service_test.mocks.dart';

/// Mock PathProvider for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  late String tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;

  @override
  Future<String?> getTemporaryPath() async => '$tempPath/temp';

  @override
  Future<String?> getApplicationSupportPath() async => '$tempPath/support';

  @override
  Future<String?> getLibraryPath() async => '$tempPath/library';

  @override
  Future<String?> getExternalStoragePath() async => null;

  @override
  Future<List<String>?> getExternalCachePaths() async => null;

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async => null;

  @override
  Future<String?> getDownloadsPath() async => '$tempPath/downloads';
}

void main() {
  late MockDatabaseHelper mockDb;
  late MockDatabase mockDatabase;
  late ImageCleanupService cleanupService;
  late MockPathProviderPlatform mockPathProvider;
  late Directory tempDir;

  setUp(() async {
    mockDb = MockDatabaseHelper();
    mockDatabase = MockDatabase();

    // 創建臨時目錄
    tempDir = await Directory.systemTemp.createTemp('cleanup_test_');

    // 設置 mock path provider
    mockPathProvider = MockPathProviderPlatform();
    mockPathProvider.tempPath = tempDir.path;
    PathProviderPlatform.instance = mockPathProvider;
    await PathValidator.initialize();

    when(mockDb.database).thenAnswer((_) async => mockDatabase);

    cleanupService = ImageCleanupService(mockDb);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ImageCleanupService', () {
    test('receipts 目錄不存在時應返回空結果', () async {
      final result = await cleanupService.cleanupOrphanedImages();

      expect(result.isSuccess, true);
      result.onSuccess((cleanup) {
        expect(cleanup.deletedCount, 0);
        expect(cleanup.freedBytes, 0);
        expect(cleanup.hasCleanup, false);
      });
    });

    test('無孤立檔案時應返回空結果', () async {
      // 創建 receipts 目錄和圖片
      final receiptsDir = Directory('${tempDir.path}/receipts/2025-01');
      await receiptsDir.create(recursive: true);
      final imageFile = File('${receiptsDir.path}/test.jpg');
      await imageFile.writeAsString('test image data');

      // 設置 mock 資料庫返回對應記錄
      when(mockDatabase.query(
        'expenses',
        columns: ['receipt_image_path', 'thumbnail_path'],
      )).thenAnswer((_) async => [
        {'receipt_image_path': imageFile.path, 'thumbnail_path': null},
      ]);

      final result = await cleanupService.cleanupOrphanedImages();

      expect(result.isSuccess, true);
      result.onSuccess((cleanup) {
        expect(cleanup.deletedCount, 0);
        expect(cleanup.hasCleanup, false);
      });

      // 確認檔案還在
      expect(await imageFile.exists(), true);
    });

    test('應刪除孤立的圖片檔案', () async {
      // 創建 receipts 目錄和圖片
      final receiptsDir = Directory('${tempDir.path}/receipts/2025-01');
      await receiptsDir.create(recursive: true);
      final orphanedFile = File('${receiptsDir.path}/orphaned.jpg');
      await orphanedFile.writeAsString('orphaned image data');
      final orphanedSize = await orphanedFile.length();

      // 資料庫中沒有對應記錄
      when(mockDatabase.query(
        'expenses',
        columns: ['receipt_image_path', 'thumbnail_path'],
      )).thenAnswer((_) async => []);

      final result = await cleanupService.cleanupOrphanedImages();

      expect(result.isSuccess, true);
      result.onSuccess((cleanup) {
        expect(cleanup.deletedCount, 1);
        expect(cleanup.freedBytes, orphanedSize);
        expect(cleanup.hasCleanup, true);
      });

      // 確認檔案已刪除
      expect(await orphanedFile.exists(), false);
    });

    test('應保留資料庫引用的檔案並刪除孤立檔案', () async {
      // 創建 receipts 目錄
      final receiptsDir = Directory('${tempDir.path}/receipts/2025-01');
      await receiptsDir.create(recursive: true);

      // 創建兩個檔案：一個有引用，一個孤立
      final referencedFile = File('${receiptsDir.path}/referenced.jpg');
      await referencedFile.writeAsString('referenced image data');

      final orphanedFile = File('${receiptsDir.path}/orphaned.png');
      await orphanedFile.writeAsString('orphaned image data');

      // 資料庫只引用一個檔案
      when(mockDatabase.query(
        'expenses',
        columns: ['receipt_image_path', 'thumbnail_path'],
      )).thenAnswer((_) async => [
        {'receipt_image_path': referencedFile.path, 'thumbnail_path': null},
      ]);

      final result = await cleanupService.cleanupOrphanedImages();

      expect(result.isSuccess, true);
      result.onSuccess((cleanup) {
        expect(cleanup.deletedCount, 1);
      });

      // 確認引用的檔案還在
      expect(await referencedFile.exists(), true);
      // 確認孤立的檔案已刪除
      expect(await orphanedFile.exists(), false);
    });

    test('應同時檢查 receipt_image_path 和 thumbnail_path', () async {
      final receiptsDir = Directory('${tempDir.path}/receipts/2025-01');
      await receiptsDir.create(recursive: true);

      // 創建兩個檔案
      final fullImage = File('${receiptsDir.path}/full.jpg');
      await fullImage.writeAsString('full image');

      final thumbnail = File('${receiptsDir.path}/thumb.jpg');
      await thumbnail.writeAsString('thumbnail');

      // 資料庫引用兩個檔案
      when(mockDatabase.query(
        'expenses',
        columns: ['receipt_image_path', 'thumbnail_path'],
      )).thenAnswer((_) async => [
        {'receipt_image_path': fullImage.path, 'thumbnail_path': thumbnail.path},
      ]);

      final result = await cleanupService.cleanupOrphanedImages();

      expect(result.isSuccess, true);
      result.onSuccess((cleanup) {
        expect(cleanup.deletedCount, 0);
      });

      // 確認兩個檔案都還在
      expect(await fullImage.exists(), true);
      expect(await thumbnail.exists(), true);
    });


    test('應只處理 jpg/jpeg/png 檔案', () async {
      final receiptsDir = Directory('${tempDir.path}/receipts/2025-01');
      await receiptsDir.create(recursive: true);

      // 創建不同類型的檔案
      final jpgFile = File('${receiptsDir.path}/image.jpg');
      await jpgFile.writeAsString('jpg');

      final txtFile = File('${receiptsDir.path}/notes.txt');
      await txtFile.writeAsString('txt');

      // 資料庫無引用
      when(mockDatabase.query(
        'expenses',
        columns: ['receipt_image_path', 'thumbnail_path'],
      )).thenAnswer((_) async => []);

      final result = await cleanupService.cleanupOrphanedImages();

      expect(result.isSuccess, true);
      result.onSuccess((cleanup) {
        // 只有 jpg 被計為孤立檔案
        expect(cleanup.deletedCount, 1);
      });

      // jpg 應被刪除
      expect(await jpgFile.exists(), false);
      // txt 應保留（不是圖片）
      expect(await txtFile.exists(), true);
    });

    test('應處理多個月份目錄', () async {
      // 創建多個月份目錄
      final dir202501 = Directory('${tempDir.path}/receipts/2025-01');
      await dir202501.create(recursive: true);
      final file1 = File('${dir202501.path}/orphan1.jpg');
      await file1.writeAsString('data1');

      final dir202502 = Directory('${tempDir.path}/receipts/2025-02');
      await dir202502.create(recursive: true);
      final file2 = File('${dir202502.path}/orphan2.jpeg');
      await file2.writeAsString('data2');

      // 資料庫無引用
      when(mockDatabase.query(
        'expenses',
        columns: ['receipt_image_path', 'thumbnail_path'],
      )).thenAnswer((_) async => []);

      final result = await cleanupService.cleanupOrphanedImages();

      expect(result.isSuccess, true);
      result.onSuccess((cleanup) {
        expect(cleanup.deletedCount, 2);
      });

      expect(await file1.exists(), false);
      expect(await file2.exists(), false);
    });
  });

  group('CleanupResult', () {
    test('empty() 應創建空結果', () {
      final result = CleanupResult.empty();
      expect(result.deletedCount, 0);
      expect(result.freedBytes, 0);
      expect(result.hasCleanup, false);
    });

    test('hasCleanup 應正確判斷', () {
      const withCleanup = CleanupResult(deletedCount: 1, freedBytes: 100);
      expect(withCleanup.hasCleanup, true);

      const withoutCleanup = CleanupResult(deletedCount: 0, freedBytes: 0);
      expect(withoutCleanup.hasCleanup, false);
    });

    test('toString 應返回正確格式', () {
      const result = CleanupResult(deletedCount: 5, freedBytes: 1024);
      expect(
        result.toString(),
        'CleanupResult(deletedCount: 5, freedBytes: 1024)',
      );
    });
  });

  group('清理間隔常數', () {
    test('清理間隔應為 24 小時', () {
      expect(
        ImageCleanupService.cleanupInterval,
        const Duration(hours: 24),
      );
    });

    test('應有 lastCleanupKey 用於儲存上次清理時間', () {
      expect(ImageCleanupService.lastCleanupKey, isNotEmpty);
    });
  });
}
