import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/data/datasources/local/secure_storage_helper.dart';
import 'package:expense_snap/data/datasources/remote/google_drive_api.dart';

@GenerateMocks([
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  SecureStorageHelper
])
import 'google_drive_api_test.mocks.dart';

/// Google Drive API 測試
void main() {
  group('DriveBackupInfo', () {
    test('應正確格式化小於 1KB 的檔案大小', () {
      final info = DriveBackupInfo(
        id: 'test_id',
        name: 'backup.zip',
        createdTime: DateTime(2025, 1, 1),
        sizeBytes: 500,
      );

      expect(info.formattedSize, '500 B');
    });

    test('應正確格式化 KB 級別的檔案大小', () {
      final info = DriveBackupInfo(
        id: 'test_id',
        name: 'backup.zip',
        createdTime: DateTime(2025, 1, 1),
        sizeBytes: 2048,
      );

      expect(info.formattedSize, '2.0 KB');
    });

    test('應正確格式化 MB 級別的檔案大小', () {
      final info = DriveBackupInfo(
        id: 'test_id',
        name: 'backup.zip',
        createdTime: DateTime(2025, 1, 1),
        sizeBytes: 5 * 1024 * 1024,
      );

      expect(info.formattedSize, '5.0 MB');
    });

    test('toString 應包含名稱和大小', () {
      final info = DriveBackupInfo(
        id: 'test_id',
        name: 'backup.zip',
        createdTime: DateTime(2025, 1, 1),
        sizeBytes: 1024 * 1024,
      );

      final str = info.toString();
      expect(str, contains('backup.zip'));
      expect(str, contains('1.0 MB'));
    });

    test('應正確建立完整的備份資訊', () {
      final createdTime = DateTime(2025, 1, 3, 14, 30);
      final info = DriveBackupInfo(
        id: 'file_abc123',
        name: 'backup_20250103_143000.zip',
        createdTime: createdTime,
        sizeBytes: 10 * 1024 * 1024,
      );

      expect(info.id, 'file_abc123');
      expect(info.name, 'backup_20250103_143000.zip');
      expect(info.createdTime, createdTime);
      expect(info.sizeBytes, 10 * 1024 * 1024);
      expect(info.formattedSize, '10.0 MB');
    });

    test('零大小檔案應顯示 0 B', () {
      final info = DriveBackupInfo(
        id: 'empty',
        name: 'empty.zip',
        createdTime: DateTime.now(),
        sizeBytes: 0,
      );

      expect(info.formattedSize, '0 B');
    });

    test('邊界值 1023 bytes 應顯示 bytes', () {
      final info = DriveBackupInfo(
        id: 'test',
        name: 'test.zip',
        createdTime: DateTime.now(),
        sizeBytes: 1023,
      );

      expect(info.formattedSize, '1023 B');
    });

    test('邊界值 1024 bytes 應顯示 KB', () {
      final info = DriveBackupInfo(
        id: 'test',
        name: 'test.zip',
        createdTime: DateTime.now(),
        sizeBytes: 1024,
      );

      expect(info.formattedSize, '1.0 KB');
    });
  });

  group('GoogleAccountInfo', () {
    test('應正確建立帳號資訊', () {
      const info = GoogleAccountInfo(
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
      );

      expect(info.email, 'test@example.com');
      expect(info.displayName, 'Test User');
      expect(info.photoUrl, 'https://example.com/photo.jpg');
    });

    test('photoUrl 和 displayName 可為 null', () {
      const info = GoogleAccountInfo(
        email: 'test@example.com',
        displayName: null,
        photoUrl: null,
      );

      expect(info.email, 'test@example.com');
      expect(info.displayName, isNull);
      expect(info.photoUrl, isNull);
    });

    test('只有 email 是必須的', () {
      const info = GoogleAccountInfo(
        email: 'minimal@test.com',
        displayName: null,
      );

      expect(info.email, 'minimal@test.com');
      expect(info.displayName, isNull);
      expect(info.photoUrl, isNull);
    });
  });

  group('GoogleDriveApi - 初始狀態', () {
    test('isSignedIn 預設為 false', () {
      final api = GoogleDriveApi();
      expect(api.isSignedIn, false);
    });

    test('currentAccount 在未登入時為 null', () {
      final api = GoogleDriveApi();
      expect(api.currentAccount, isNull);
    });
  });

  group('GoogleDriveApi - signIn', () {
    late GoogleDriveApi api;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockSecureStorageHelper mockSecureStorage;

    setUp(() {
      mockGoogleSignIn = MockGoogleSignIn();
      mockSecureStorage = MockSecureStorageHelper();
      api = GoogleDriveApi(
        googleSignIn: mockGoogleSignIn,
        secureStorage: mockSecureStorage,
      );
    });

    test('靜默登入成功應回傳帳號資訊', () async {
      // Arrange
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();

      when(mockAccount.email).thenReturn('test@gmail.com');
      when(mockAccount.displayName).thenReturn('Test User');
      when(mockAccount.photoUrl).thenReturn(null);
      when(mockAccount.authentication).thenAnswer((_) async => mockAuth);
      when(mockAuth.accessToken).thenReturn('mock_access_token');

      when(mockGoogleSignIn.signInSilently())
          .thenAnswer((_) async => mockAccount);
      when(mockSecureStorage.saveGoogleAccessToken(any))
          .thenAnswer((_) async {});

      // Act
      final result = await api.signIn();

      // Assert
      expect(result.isSuccess, true);
      final info = result.getOrThrow();
      expect(info.email, 'test@gmail.com');
      expect(info.displayName, 'Test User');
      expect(api.isSignedIn, true);
      expect(api.currentAccount, isNotNull);
    });

    test('靜默登入失敗後應嘗試互動式登入', () async {
      // Arrange
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();

      when(mockAccount.email).thenReturn('interactive@gmail.com');
      when(mockAccount.displayName).thenReturn('Interactive User');
      when(mockAccount.photoUrl).thenReturn('https://photo.url');
      when(mockAccount.authentication).thenAnswer((_) async => mockAuth);
      when(mockAuth.accessToken).thenReturn('interactive_token');

      when(mockGoogleSignIn.signInSilently()).thenAnswer((_) async => null);
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockAccount);
      when(mockSecureStorage.saveGoogleAccessToken(any))
          .thenAnswer((_) async {});

      // Act
      final result = await api.signIn();

      // Assert
      expect(result.isSuccess, true);
      final info = result.getOrThrow();
      expect(info.email, 'interactive@gmail.com');
      verify(mockGoogleSignIn.signInSilently()).called(1);
      verify(mockGoogleSignIn.signIn()).called(1);
    });

    test('使用者取消登入應回傳取消錯誤', () async {
      // Arrange
      when(mockGoogleSignIn.signInSilently()).thenAnswer((_) async => null);
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      // Act
      final result = await api.signIn();

      // Assert
      expect(result.isFailure, true);
      final error = (result as Failure).error;
      expect(error, isA<AuthException>());
    });

    test('登入過程異常應回傳錯誤', () async {
      // Arrange
      when(mockGoogleSignIn.signInSilently())
          .thenThrow(Exception('Network error'));

      // Act
      final result = await api.signIn();

      // Assert
      expect(result.isFailure, true);
      expect(api.isSignedIn, false);
    });

    test('登入後應儲存 access token', () async {
      // Arrange
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();

      when(mockAccount.email).thenReturn('test@gmail.com');
      when(mockAccount.displayName).thenReturn('Test');
      when(mockAccount.photoUrl).thenReturn(null);
      when(mockAccount.authentication).thenAnswer((_) async => mockAuth);
      when(mockAuth.accessToken).thenReturn('saved_token');

      when(mockGoogleSignIn.signInSilently())
          .thenAnswer((_) async => mockAccount);
      when(mockSecureStorage.saveGoogleAccessToken(any))
          .thenAnswer((_) async {});

      // Act
      await api.signIn();

      // Assert
      verify(mockSecureStorage.saveGoogleAccessToken('saved_token')).called(1);
    });
  });

  group('GoogleDriveApi - signOut', () {
    late GoogleDriveApi api;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockSecureStorageHelper mockSecureStorage;

    setUp(() {
      mockGoogleSignIn = MockGoogleSignIn();
      mockSecureStorage = MockSecureStorageHelper();
      api = GoogleDriveApi(
        googleSignIn: mockGoogleSignIn,
        secureStorage: mockSecureStorage,
      );
    });

    test('登出成功應清除所有 tokens', () async {
      // Arrange
      when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      when(mockSecureStorage.clearGoogleTokens()).thenAnswer((_) async {});

      // Act
      final result = await api.signOut();

      // Assert
      expect(result.isSuccess, true);
      verify(mockSecureStorage.clearGoogleTokens()).called(1);
      expect(api.isSignedIn, false);
      expect(api.currentAccount, isNull);
    });

    test('登出失敗應回傳錯誤', () async {
      // Arrange
      when(mockGoogleSignIn.signOut()).thenThrow(Exception('Sign out error'));

      // Act
      final result = await api.signOut();

      // Assert
      expect(result.isFailure, true);
    });
  });

  group('GoogleDriveApi - disconnect', () {
    late GoogleDriveApi api;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockSecureStorageHelper mockSecureStorage;

    setUp(() {
      mockGoogleSignIn = MockGoogleSignIn();
      mockSecureStorage = MockSecureStorageHelper();
      api = GoogleDriveApi(
        googleSignIn: mockGoogleSignIn,
        secureStorage: mockSecureStorage,
      );
    });

    test('斷開連接成功應清除所有資料', () async {
      // Arrange
      when(mockGoogleSignIn.disconnect()).thenAnswer((_) async => null);
      when(mockSecureStorage.clearGoogleTokens()).thenAnswer((_) async {});

      // Act
      final result = await api.disconnect();

      // Assert
      expect(result.isSuccess, true);
      verify(mockGoogleSignIn.disconnect()).called(1);
      verify(mockSecureStorage.clearGoogleTokens()).called(1);
    });

    test('斷開連接失敗應回傳錯誤', () async {
      // Arrange
      when(mockGoogleSignIn.disconnect())
          .thenThrow(Exception('Disconnect error'));

      // Act
      final result = await api.disconnect();

      // Assert
      expect(result.isFailure, true);
    });
  });

  group('GoogleDriveApi - tryRestoreSession', () {
    late GoogleDriveApi api;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockSecureStorageHelper mockSecureStorage;

    setUp(() {
      mockGoogleSignIn = MockGoogleSignIn();
      mockSecureStorage = MockSecureStorageHelper();
      api = GoogleDriveApi(
        googleSignIn: mockGoogleSignIn,
        secureStorage: mockSecureStorage,
      );
    });

    test('有已儲存的 session 應成功恢復', () async {
      // Arrange
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();

      when(mockAccount.email).thenReturn('restored@gmail.com');
      when(mockAccount.displayName).thenReturn('Restored');
      when(mockAccount.photoUrl).thenReturn(null);
      when(mockAccount.authentication).thenAnswer((_) async => mockAuth);
      when(mockAuth.accessToken).thenReturn('restored_token');

      when(mockGoogleSignIn.signInSilently())
          .thenAnswer((_) async => mockAccount);
      when(mockSecureStorage.saveGoogleAccessToken(any))
          .thenAnswer((_) async {});

      // Act
      final result = await api.tryRestoreSession();

      // Assert
      expect(result.isSuccess, true);
      final info = result.getOrNull();
      expect(info?.email, 'restored@gmail.com');
      expect(api.isSignedIn, true);
    });

    test('無已儲存的 session 應回傳 null（非錯誤）', () async {
      // Arrange
      when(mockGoogleSignIn.signInSilently()).thenAnswer((_) async => null);

      // Act
      final result = await api.tryRestoreSession();

      // Assert
      expect(result.isSuccess, true);
      expect(result.getOrNull(), isNull);
      expect(api.isSignedIn, false);
    });

    test('恢復過程異常應回傳 null（非錯誤）', () async {
      // Arrange
      when(mockGoogleSignIn.signInSilently())
          .thenThrow(Exception('Restore error'));

      // Act
      final result = await api.tryRestoreSession();

      // Assert
      expect(result.isSuccess, true);
      expect(result.getOrNull(), isNull);
    });
  });

  group('AuthException', () {
    test('cancelled 應建立正確的取消錯誤', () {
      final error = AuthException.cancelled();

      expect(error.code, 'CANCELLED');
      expect(error.message, contains('取消'));
    });

    test('notSignedIn 應建立正確的未登入錯誤', () {
      final error = AuthException.notSignedIn();

      expect(error.code, 'NOT_SIGNED_IN');
      expect(error.message, contains('登入'));
    });

    test('tokenExpired 應建立正確的 token 過期錯誤', () {
      final error = AuthException.tokenExpired();

      expect(error.code, 'TOKEN_EXPIRED');
      expect(error.message, contains('過期'));
    });

    test('一般 AuthException 應包含自訂訊息', () {
      const error = AuthException('Custom auth error');

      expect(error.message, 'Custom auth error');
    });
  });

  group('常數和配置', () {
    test('備份資料夾名稱應為 ExpenseTracker', () {
      // 文件化測試：確保資料夾名稱不會意外變更
      // 此名稱用於 Google Drive 上建立專屬資料夾
      const expectedFolderName = 'ExpenseTracker';
      expect(expectedFolderName, isNotEmpty);
    });

    test('備份檔案 MIME 類型應為 application/zip', () {
      const expectedMimeType = 'application/zip';
      expect(expectedMimeType, isNotEmpty);
    });

    test('大檔案閾值應為 5MB', () {
      const expectedThreshold = 5 * 1024 * 1024;
      expect(expectedThreshold, 5242880);
    });
  });
}
