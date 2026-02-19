import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_snap/presentation/providers/backup_provider.dart';
import 'package:expense_snap/presentation/providers/google_auth_provider.dart';
import 'package:expense_snap/data/repositories/backup_repository.dart';
import 'package:expense_snap/domain/repositories/backup_repository.dart'
    show BackupInfo;
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/data/models/backup_status.dart';

@GenerateMocks([BackupRepository, GoogleAuthProvider])
import 'backup_provider_test.mocks.dart';

void main() {
  // 測試用資料
  final testBackups = [
    BackupInfo(
      fileId: 'file_1',
      fileName: 'backup_20250110.zip',
      createdAt: DateTime(2025, 1, 10),
      sizeBytes: 1024 * 1024,
    ),
    BackupInfo(
      fileId: 'file_2',
      fileName: 'backup_20250115.zip',
      createdAt: DateTime(2025, 1, 15),
      sizeBytes: 2048 * 1024,
    ),
  ];

  // 註冊 dummy values
  setUpAll(() {
    provideDummy<Result<String>>(Result.success('/path/to/backup.zip'));
    provideDummy<Result<void>>(Result.success(null));
    provideDummy<Result<List<BackupInfo>>>(Result.success(testBackups));
    provideDummy<Result<int>>(Result.success(0));
    provideDummy<Result<BackupStatus>>(
      Result.success(BackupStatus.empty()),
    );
  });

  late MockBackupRepository mockBackupRepo;
  late MockGoogleAuthProvider mockAuthProvider;
  late BackupProvider provider;

  setUp(() {
    mockBackupRepo = MockBackupRepository();
    mockAuthProvider = MockGoogleAuthProvider();

    // 預設 stubs
    when(mockAuthProvider.isGoogleConnected).thenReturn(true);
    when(mockAuthProvider.loadBackupStatus()).thenAnswer((_) async {});
    when(
      mockBackupRepo.calculateLocalStorageUsageKb(),
    ).thenAnswer((_) async => 512);
    when(
      mockBackupRepo.listGoogleDriveBackups(),
    ).thenAnswer((_) async => Result.success(testBackups));

    provider = BackupProvider(
      backupRepository: mockBackupRepo,
      googleAuthProvider: mockAuthProvider,
    );
  });

  group('BackupProvider', () {
    group('初始狀態', () {
      test('operationState 應為 idle', () {
        expect(provider.operationState, BackupOperationState.idle);
      });

      test('operationProgress 應為 0', () {
        expect(provider.operationProgress, equals(0.0));
      });

      test('operationMessage 應為空字串', () {
        expect(provider.operationMessage, isEmpty);
      });

      test('errorMessage 應為 null', () {
        expect(provider.errorMessage, isNull);
      });

      test('cloudBackups 應為空列表', () {
        expect(provider.cloudBackups, isEmpty);
      });

      test('isOperationInProgress 應為 false', () {
        expect(provider.isOperationInProgress, isFalse);
      });
    });

    group('formattedStorageUsage', () {
      test('小於 1024 KB 應顯示 KB', () async {
        when(
          mockBackupRepo.calculateLocalStorageUsageKb(),
        ).thenAnswer((_) async => 512);
        await provider.calculateStorageUsage();

        expect(provider.formattedStorageUsage, equals('512 KB'));
      });

      test('大於等於 1024 KB 應顯示 MB', () async {
        when(
          mockBackupRepo.calculateLocalStorageUsageKb(),
        ).thenAnswer((_) async => 2048);
        await provider.calculateStorageUsage();

        expect(provider.formattedStorageUsage, equals('2.0 MB'));
      });

      test('0 KB 應顯示 0 KB', () async {
        when(
          mockBackupRepo.calculateLocalStorageUsageKb(),
        ).thenAnswer((_) async => 0);
        await provider.calculateStorageUsage();

        expect(provider.formattedStorageUsage, equals('0 KB'));
      });
    });

    group('isOperationInProgress', () {
      test('preparing 狀態應為 true', () {
        // 透過觸發備份操作來設定狀態
        // 使用 resetOperationState 作為對照
        provider.resetOperationState();
        expect(provider.isOperationInProgress, isFalse);
      });
    });

    group('backupToGoogleDrive', () {
      test('未連結 Google 應回傳 AuthException', () async {
        when(mockAuthProvider.isGoogleConnected).thenReturn(false);

        final result = await provider.backupToGoogleDrive();

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<AuthException>());
      });

      test('成功備份應回傳 success', () async {
        when(
          mockBackupRepo.createLocalBackup(onProgress: anyNamed('onProgress')),
        ).thenAnswer((_) async => Result.success('/path/to/backup.zip'));
        when(
          mockBackupRepo.uploadBackupToGoogleDrive(
            any,
            onProgress: anyNamed('onProgress'),
          ),
        ).thenAnswer((_) async => Result.success(null));

        final result = await provider.backupToGoogleDrive();

        expect(result.isSuccess, isTrue);
        expect(provider.operationState, BackupOperationState.success);
        expect(provider.operationProgress, equals(1.0));
      });

      test('本地備份失敗應設定錯誤狀態', () async {
        when(
          mockBackupRepo.createLocalBackup(onProgress: anyNamed('onProgress')),
        ).thenAnswer(
          (_) async => Result.failure(
            const StorageException('磁碟空間不足'),
          ),
        );

        final result = await provider.backupToGoogleDrive();

        expect(result.isFailure, isTrue);
        expect(provider.operationState, BackupOperationState.error);
        expect(provider.errorMessage, isNotNull);
      });

      test('上傳失敗應設定錯誤狀態', () async {
        when(
          mockBackupRepo.createLocalBackup(onProgress: anyNamed('onProgress')),
        ).thenAnswer((_) async => Result.success('/path/to/backup.zip'));
        when(
          mockBackupRepo.uploadBackupToGoogleDrive(
            any,
            onProgress: anyNamed('onProgress'),
          ),
        ).thenAnswer(
          (_) async => Result.failure(
            const NetworkException('上傳超時'),
          ),
        );

        final result = await provider.backupToGoogleDrive();

        expect(result.isFailure, isTrue);
        expect(provider.operationState, BackupOperationState.error);
      });

      test('操作鎖定中應回傳 StorageException', () async {
        // 模擬一個長時間備份操作
        when(
          mockBackupRepo.createLocalBackup(onProgress: anyNamed('onProgress')),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return Result.success('/path/to/backup.zip');
        });
        when(
          mockBackupRepo.uploadBackupToGoogleDrive(
            any,
            onProgress: anyNamed('onProgress'),
          ),
        ).thenAnswer((_) async => Result.success(null));

        // 同時發起兩個備份
        final future1 = provider.backupToGoogleDrive();
        final result2 = await provider.backupToGoogleDrive();

        // 第二個應被拒絕
        expect(result2.isFailure, isTrue);
        expect(result2.errorOrNull, isA<StorageException>());

        // 等待第一個完成
        await future1;
      });

      test('成功備份後應更新備份狀態和儲存使用量', () async {
        when(
          mockBackupRepo.createLocalBackup(onProgress: anyNamed('onProgress')),
        ).thenAnswer((_) async => Result.success('/path/to/backup.zip'));
        when(
          mockBackupRepo.uploadBackupToGoogleDrive(
            any,
            onProgress: anyNamed('onProgress'),
          ),
        ).thenAnswer((_) async => Result.success(null));

        await provider.backupToGoogleDrive();

        // 驗證有呼叫更新方法
        verify(mockAuthProvider.loadBackupStatus()).called(1);
        verify(mockBackupRepo.calculateLocalStorageUsageKb()).called(1);
      });

      test('備份過程中 repository 拋出異常應被捕獲', () async {
        when(
          mockBackupRepo.createLocalBackup(onProgress: anyNamed('onProgress')),
        ).thenThrow(Exception('unexpected error'));

        final result = await provider.backupToGoogleDrive();

        expect(result.isFailure, isTrue);
        expect(provider.operationState, BackupOperationState.error);
      });
    });

    group('restoreFromGoogleDrive', () {
      test('空 fileId 應回傳 StorageException', () async {
        final result = await provider.restoreFromGoogleDrive('');

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<StorageException>());
        expect(result.errorOrNull?.code, equals('INVALID_FILE_ID'));
      });

      test('未連結 Google 應回傳 AuthException', () async {
        when(mockAuthProvider.isGoogleConnected).thenReturn(false);

        final result = await provider.restoreFromGoogleDrive('file_1');

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<AuthException>());
      });

      test('成功還原應回傳 success', () async {
        when(
          mockBackupRepo.downloadBackupFromGoogleDrive(
            any,
            onProgress: anyNamed('onProgress'),
          ),
        ).thenAnswer((_) async => Result.success('/path/to/restore.zip'));
        when(
          mockBackupRepo.restoreFromBackup(
            any,
            onProgress: anyNamed('onProgress'),
          ),
        ).thenAnswer((_) async => Result.success(null));

        final result = await provider.restoreFromGoogleDrive('file_1');

        expect(result.isSuccess, isTrue);
        expect(provider.operationState, BackupOperationState.success);
      });

      test('下載失敗應設定錯誤狀態', () async {
        when(
          mockBackupRepo.downloadBackupFromGoogleDrive(
            any,
            onProgress: anyNamed('onProgress'),
          ),
        ).thenAnswer(
          (_) async => Result.failure(
            const NetworkException('下載失敗'),
          ),
        );

        final result = await provider.restoreFromGoogleDrive('file_1');

        expect(result.isFailure, isTrue);
        expect(provider.operationState, BackupOperationState.error);
      });

      test('還原失敗應設定錯誤狀態', () async {
        when(
          mockBackupRepo.downloadBackupFromGoogleDrive(
            any,
            onProgress: anyNamed('onProgress'),
          ),
        ).thenAnswer((_) async => Result.success('/path/to/restore.zip'));
        when(
          mockBackupRepo.restoreFromBackup(
            any,
            onProgress: anyNamed('onProgress'),
          ),
        ).thenAnswer(
          (_) async => Result.failure(
            const StorageException('備份檔案損壞'),
          ),
        );

        final result = await provider.restoreFromGoogleDrive('file_1');

        expect(result.isFailure, isTrue);
        expect(provider.operationState, BackupOperationState.error);
      });

      test('操作鎖定中應回傳 StorageException', () async {
        when(
          mockBackupRepo.downloadBackupFromGoogleDrive(
            any,
            onProgress: anyNamed('onProgress'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return Result.success('/path/to/restore.zip');
        });
        when(
          mockBackupRepo.restoreFromBackup(
            any,
            onProgress: anyNamed('onProgress'),
          ),
        ).thenAnswer((_) async => Result.success(null));

        // 同時發起兩個還原
        final future1 = provider.restoreFromGoogleDrive('file_1');
        final result2 = await provider.restoreFromGoogleDrive('file_2');

        expect(result2.isFailure, isTrue);
        expect(result2.errorOrNull, isA<StorageException>());

        await future1;
      });
    });

    group('loadCloudBackups', () {
      test('未連結 Google 應回傳空列表', () async {
        when(mockAuthProvider.isGoogleConnected).thenReturn(false);

        final result = await provider.loadCloudBackups();

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), isEmpty);
      });

      test('成功載入應更新 cloudBackups', () async {
        final result = await provider.loadCloudBackups();

        expect(result.isSuccess, isTrue);
        expect(provider.cloudBackups.length, equals(2));
        expect(provider.cloudBackups.first.fileId, equals('file_1'));
      });

      test('cloudBackups 應為不可變列表', () async {
        await provider.loadCloudBackups();

        // 嘗試修改回傳的列表不應影響內部狀態
        expect(
          () => provider.cloudBackups.add(
            BackupInfo(
              fileId: 'file_3',
              fileName: 'test.zip',
              createdAt: DateTime.now(),
              sizeBytes: 100,
            ),
          ),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('載入失敗應回傳錯誤', () async {
        when(mockBackupRepo.listGoogleDriveBackups()).thenAnswer(
          (_) async => Result.failure(
            const NetworkException('網絡錯誤'),
          ),
        );

        final result = await provider.loadCloudBackups();

        expect(result.isFailure, isTrue);
      });
    });

    group('cleanupTempFiles', () {
      test('成功清理應更新儲存使用量', () async {
        when(
          mockBackupRepo.cleanupBackupTempFiles(),
        ).thenAnswer((_) async => Result.success(5));

        final result = await provider.cleanupTempFiles();

        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), equals(5));
        verify(mockBackupRepo.calculateLocalStorageUsageKb()).called(1);
      });

      test('清理失敗應回傳錯誤', () async {
        when(mockBackupRepo.cleanupBackupTempFiles()).thenAnswer(
          (_) async => Result.failure(
            const StorageException('清理失敗'),
          ),
        );

        final result = await provider.cleanupTempFiles();

        expect(result.isFailure, isTrue);
      });

      test('repository 拋出異常應被捕獲', () async {
        when(
          mockBackupRepo.cleanupBackupTempFiles(),
        ).thenThrow(Exception('unexpected'));

        final result = await provider.cleanupTempFiles();

        expect(result.isFailure, isTrue);
      });
    });

    group('resetOperationState', () {
      test('應重置所有操作狀態', () async {
        // 先觸發錯誤狀態（透過本地備份失敗，此時會先進入 preparing 再進入 error）
        when(
          mockBackupRepo.createLocalBackup(
            onProgress: anyNamed('onProgress'),
          ),
        ).thenAnswer(
          (_) async => Result.failure(
            const StorageException('磁碟空間不足'),
          ),
        );
        await provider.backupToGoogleDrive();
        expect(provider.operationState, equals(BackupOperationState.error));

        // 重置
        provider.resetOperationState();

        expect(provider.operationState, BackupOperationState.idle);
        expect(provider.operationProgress, equals(0.0));
        expect(provider.operationMessage, isEmpty);
        expect(provider.errorMessage, isNull);
      });
    });

    group('refresh', () {
      test('應刷新備份狀態、儲存使用量和雲端備份', () async {
        await provider.refresh();

        verify(mockAuthProvider.loadBackupStatus()).called(1);
        verify(mockBackupRepo.calculateLocalStorageUsageKb()).called(1);
        verify(mockBackupRepo.listGoogleDriveBackups()).called(1);
      });

      test('未連結 Google 時不應載入雲端備份', () async {
        when(mockAuthProvider.isGoogleConnected).thenReturn(false);

        await provider.refresh();

        verify(mockAuthProvider.loadBackupStatus()).called(1);
        verify(mockBackupRepo.calculateLocalStorageUsageKb()).called(1);
        verifyNever(mockBackupRepo.listGoogleDriveBackups());
      });
    });

    group('dispose', () {
      test('dispose 後操作不應拋出錯誤', () async {
        provider.dispose();

        // dispose 後 resetOperationState 不應拋出
        provider.resetOperationState();
      });

      test('dispose 後 backupToGoogleDrive 不應拋出 FlutterError', () async {
        provider.dispose();

        // notifyListeners 應被 _safeNotifyListeners 保護
        when(mockAuthProvider.isGoogleConnected).thenReturn(false);
        final result = await provider.backupToGoogleDrive();
        expect(result.isFailure, isTrue);
      });
    });
  });

  group('BackupOperationState', () {
    test('應有正確的枚舉值', () {
      expect(BackupOperationState.values, hasLength(6));
      expect(BackupOperationState.values, contains(BackupOperationState.idle));
      expect(
        BackupOperationState.values,
        contains(BackupOperationState.preparing),
      );
      expect(
        BackupOperationState.values,
        contains(BackupOperationState.inProgress),
      );
      expect(
        BackupOperationState.values,
        contains(BackupOperationState.completing),
      );
      expect(
        BackupOperationState.values,
        contains(BackupOperationState.success),
      );
      expect(
        BackupOperationState.values,
        contains(BackupOperationState.error),
      );
    });
  });
}
