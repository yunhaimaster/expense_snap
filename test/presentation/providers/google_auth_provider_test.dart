import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_snap/presentation/providers/google_auth_provider.dart';
import 'package:expense_snap/data/repositories/backup_repository.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/data/models/backup_status.dart';

@GenerateMocks([BackupRepository])
import 'google_auth_provider_test.mocks.dart';

void main() {
  // 測試用資料
  final connectedStatus = BackupStatus(
    lastBackupAt: DateTime(2025, 1, 15),
    lastBackupCount: 10,
    lastBackupSizeKb: 2048,
    googleEmail: 'test@gmail.com',
  );

  final disconnectedStatus = BackupStatus.empty();

  // 註冊 dummy values
  setUpAll(() {
    provideDummy<Result<BackupStatus>>(
      Result.success(disconnectedStatus),
    );
    provideDummy<Result<String>>(Result.success('test@gmail.com'));
    provideDummy<Result<String?>>(Result.success(null));
    provideDummy<Result<void>>(Result.success(null));
  });

  late MockBackupRepository mockBackupRepo;
  late GoogleAuthProvider provider;

  setUp(() {
    mockBackupRepo = MockBackupRepository();

    // 預設 stubs
    when(
      mockBackupRepo.getBackupStatus(),
    ).thenAnswer((_) async => Result.success(disconnectedStatus));
    when(
      mockBackupRepo.tryRestoreGoogleSession(),
    ).thenAnswer((_) async => Result.success(null));

    provider = GoogleAuthProvider(backupRepository: mockBackupRepo);
  });

  group('GoogleAuthProvider', () {
    group('初始狀態', () {
      test('backupStatus 應為 empty', () {
        expect(provider.backupStatus.isGoogleConnected, isFalse);
        expect(provider.backupStatus.lastBackupCount, equals(0));
      });

      test('errorMessage 應為 null', () {
        expect(provider.errorMessage, isNull);
      });

      test('isGoogleConnected 應為 false', () {
        expect(provider.isGoogleConnected, isFalse);
      });
    });

    group('initialize', () {
      test('應嘗試恢復 session 並載入備份狀態', () async {
        await provider.initialize();

        verify(mockBackupRepo.tryRestoreGoogleSession()).called(1);
        verify(mockBackupRepo.getBackupStatus()).called(1);
      });

      test('session 恢復失敗不應拋出異常', () async {
        when(
          mockBackupRepo.tryRestoreGoogleSession(),
        ).thenThrow(Exception('Session restore failed'));

        // 不應拋出異常
        await provider.initialize();
      });

      test('成功恢復 session 後應更新狀態', () async {
        when(
          mockBackupRepo.tryRestoreGoogleSession(),
        ).thenAnswer((_) async => Result.success('test@gmail.com'));
        when(
          mockBackupRepo.getBackupStatus(),
        ).thenAnswer((_) async => Result.success(connectedStatus));

        await provider.initialize();

        expect(provider.isGoogleConnected, isTrue);
        expect(provider.backupStatus.googleEmail, equals('test@gmail.com'));
      });
    });

    group('loadBackupStatus', () {
      test('成功載入應更新 backupStatus', () async {
        when(
          mockBackupRepo.getBackupStatus(),
        ).thenAnswer((_) async => Result.success(connectedStatus));

        await provider.loadBackupStatus();

        expect(provider.backupStatus.googleEmail, equals('test@gmail.com'));
        expect(provider.backupStatus.lastBackupCount, equals(10));
      });

      test('載入失敗不應更新 backupStatus', () async {
        // 先載入成功的狀態
        when(
          mockBackupRepo.getBackupStatus(),
        ).thenAnswer((_) async => Result.success(connectedStatus));
        await provider.loadBackupStatus();
        expect(provider.isGoogleConnected, isTrue);

        // 再載入失敗
        when(mockBackupRepo.getBackupStatus()).thenAnswer(
          (_) async => Result.failure(
            DatabaseException.queryFailed('查詢失敗'),
          ),
        );
        await provider.loadBackupStatus();

        // 狀態應保持不變
        expect(provider.isGoogleConnected, isTrue);
      });
    });

    group('connectGoogle', () {
      test('成功登入應更新狀態', () async {
        when(
          mockBackupRepo.signInWithGoogle(),
        ).thenAnswer((_) async => Result.success('user@gmail.com'));
        when(
          mockBackupRepo.getBackupStatus(),
        ).thenAnswer((_) async => Result.success(connectedStatus));

        final result = await provider.connectGoogle();

        expect(result.isSuccess, isTrue);
        expect(provider.errorMessage, isNull);
        verify(mockBackupRepo.signInWithGoogle()).called(1);
        // 登入後應重新載入備份狀態
        verify(mockBackupRepo.getBackupStatus()).called(1);
      });

      test('登入失敗應設定 errorMessage', () async {
        when(mockBackupRepo.signInWithGoogle()).thenAnswer(
          (_) async => Result.failure(
            AuthException.cancelled(),
          ),
        );

        final result = await provider.connectGoogle();

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<AuthException>());
        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains('取消'));
      });

      test('操作鎖定中應回傳 StorageException', () async {
        // 模擬長時間登入操作
        when(mockBackupRepo.signInWithGoogle()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return Result.success('user@gmail.com');
        });
        when(
          mockBackupRepo.getBackupStatus(),
        ).thenAnswer((_) async => Result.success(connectedStatus));

        // 同時發起兩個登入
        final future1 = provider.connectGoogle();
        final result2 = await provider.connectGoogle();

        // 第二個應被拒絕
        expect(result2.isFailure, isTrue);
        expect(result2.errorOrNull, isA<StorageException>());

        await future1;
      });

      test('成功登入後 errorMessage 應被清除', () async {
        // 先觸發錯誤
        when(mockBackupRepo.signInWithGoogle()).thenAnswer(
          (_) async => Result.failure(AuthException.cancelled()),
        );
        await provider.connectGoogle();
        expect(provider.errorMessage, isNotNull);

        // 再成功登入
        when(
          mockBackupRepo.signInWithGoogle(),
        ).thenAnswer((_) async => Result.success('user@gmail.com'));
        when(
          mockBackupRepo.getBackupStatus(),
        ).thenAnswer((_) async => Result.success(connectedStatus));
        await provider.connectGoogle();

        expect(provider.errorMessage, isNull);
      });
    });

    group('disconnectGoogle', () {
      setUp(() async {
        // 先建立連結狀態
        when(
          mockBackupRepo.signInWithGoogle(),
        ).thenAnswer((_) async => Result.success('user@gmail.com'));
        when(
          mockBackupRepo.getBackupStatus(),
        ).thenAnswer((_) async => Result.success(connectedStatus));
        await provider.connectGoogle();
      });

      test('成功登出應更新狀態', () async {
        when(
          mockBackupRepo.signOutFromGoogle(),
        ).thenAnswer((_) async => Result.success(null));
        when(
          mockBackupRepo.getBackupStatus(),
        ).thenAnswer((_) async => Result.success(disconnectedStatus));

        final result = await provider.disconnectGoogle();

        expect(result.isSuccess, isTrue);
        expect(provider.errorMessage, isNull);
        verify(mockBackupRepo.signOutFromGoogle()).called(1);
      });

      test('登出失敗應設定 errorMessage', () async {
        when(mockBackupRepo.signOutFromGoogle()).thenAnswer(
          (_) async => Result.failure(
            const NetworkException('無法連線'),
          ),
        );

        final result = await provider.disconnectGoogle();

        expect(result.isFailure, isTrue);
        expect(provider.errorMessage, isNotNull);
      });

      test('操作鎖定中應回傳 StorageException', () async {
        when(mockBackupRepo.signOutFromGoogle()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return Result.success(null);
        });
        when(
          mockBackupRepo.getBackupStatus(),
        ).thenAnswer((_) async => Result.success(disconnectedStatus));

        // 同時發起兩個登出
        final future1 = provider.disconnectGoogle();
        final result2 = await provider.disconnectGoogle();

        expect(result2.isFailure, isTrue);
        expect(result2.errorOrNull, isA<StorageException>());

        await future1;
      });
    });

    group('dispose', () {
      test('dispose 後操作不應拋出 FlutterError', () async {
        provider.dispose();

        // loadBackupStatus 在 dispose 後不應拋出
        await provider.loadBackupStatus();
      });

      test('dispose 後 connectGoogle 不應拋出', () async {
        provider.dispose();

        when(mockBackupRepo.signInWithGoogle()).thenAnswer(
          (_) async => Result.failure(AuthException.cancelled()),
        );
        final result = await provider.connectGoogle();
        expect(result.isFailure, isTrue);
      });
    });
  });
}
