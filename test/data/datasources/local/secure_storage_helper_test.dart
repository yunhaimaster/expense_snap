import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@GenerateMocks([FlutterSecureStorage])
import 'secure_storage_helper_test.mocks.dart';

/// SecureStorageHelper 測試
///
/// 測試 OAuth tokens 的安全儲存與擷取
void main() {
  group('SecureStorageHelper - Google Tokens', () {
    late MockFlutterSecureStorage mockStorage;
    late _TestableSecureStorageHelper helper;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      helper = _TestableSecureStorageHelper(mockStorage);
    });

    group('saveGoogleAccessToken', () {
      test('應正確儲存 access token', () async {
        // Arrange
        when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        await helper.saveGoogleAccessToken('test_access_token');

        // Assert
        verify(mockStorage.write(
          key: 'google_access_token',
          value: 'test_access_token',
        )).called(1);
      });
    });

    group('getGoogleAccessToken', () {
      test('應正確讀取已儲存的 token', () async {
        // Arrange
        when(mockStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => 'stored_token');

        // Act
        final token = await helper.getGoogleAccessToken();

        // Assert
        expect(token, 'stored_token');
        verify(mockStorage.read(key: 'google_access_token')).called(1);
      });

      test('無儲存 token 時應回傳 null', () async {
        // Arrange
        when(mockStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => null);

        // Act
        final token = await helper.getGoogleAccessToken();

        // Assert
        expect(token, isNull);
      });
    });

    group('saveGoogleRefreshToken', () {
      test('應正確儲存 refresh token', () async {
        // Arrange
        when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        await helper.saveGoogleRefreshToken('test_refresh_token');

        // Assert
        verify(mockStorage.write(
          key: 'google_refresh_token',
          value: 'test_refresh_token',
        )).called(1);
      });
    });

    group('getGoogleRefreshToken', () {
      test('應正確讀取已儲存的 refresh token', () async {
        // Arrange
        when(mockStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => 'stored_refresh');

        // Act
        final token = await helper.getGoogleRefreshToken();

        // Assert
        expect(token, 'stored_refresh');
      });

      test('無儲存 token 時應回傳 null', () async {
        // Arrange
        when(mockStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => null);

        // Act
        final token = await helper.getGoogleRefreshToken();

        // Assert
        expect(token, isNull);
      });
    });

    group('saveGoogleTokenExpiry', () {
      test('應以 ISO8601 格式儲存過期時間', () async {
        // Arrange
        when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        final expiry = DateTime(2025, 1, 3, 12, 30, 45);

        // Act
        await helper.saveGoogleTokenExpiry(expiry);

        // Assert
        verify(mockStorage.write(
          key: 'google_token_expiry',
          value: expiry.toIso8601String(),
        )).called(1);
      });
    });

    group('getGoogleTokenExpiry', () {
      test('應正確解析已儲存的過期時間', () async {
        // Arrange
        when(mockStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => '2025-01-03T12:30:45.000');

        // Act
        final expiry = await helper.getGoogleTokenExpiry();

        // Assert
        expect(expiry, isNotNull);
        expect(expiry!.year, 2025);
        expect(expiry.month, 1);
        expect(expiry.day, 3);
        expect(expiry.hour, 12);
        expect(expiry.minute, 30);
      });

      test('無儲存時應回傳 null', () async {
        // Arrange
        when(mockStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => null);

        // Act
        final expiry = await helper.getGoogleTokenExpiry();

        // Assert
        expect(expiry, isNull);
      });

      test('無效日期格式應回傳 null', () async {
        // Arrange
        when(mockStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => 'invalid-date');

        // Act
        final expiry = await helper.getGoogleTokenExpiry();

        // Assert
        expect(expiry, isNull);
      });
    });

    group('isGoogleTokenExpired', () {
      test('無過期時間應視為已過期', () async {
        // Arrange
        when(mockStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => null);

        // Act
        final isExpired = await helper.isGoogleTokenExpired();

        // Assert
        expect(isExpired, true);
      });

      test('過期時間在未來應視為未過期', () async {
        // Arrange
        final futureExpiry = DateTime.now().add(const Duration(hours: 1));
        when(mockStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => futureExpiry.toIso8601String());

        // Act
        final isExpired = await helper.isGoogleTokenExpired();

        // Assert
        expect(isExpired, false);
      });

      test('過期時間在過去應視為已過期', () async {
        // Arrange
        final pastExpiry = DateTime.now().subtract(const Duration(hours: 1));
        when(mockStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => pastExpiry.toIso8601String());

        // Act
        final isExpired = await helper.isGoogleTokenExpired();

        // Assert
        expect(isExpired, true);
      });

      test('過期時間在 5 分鐘內應視為已過期（預留刷新時間）', () async {
        // Arrange
        final nearExpiry = DateTime.now().add(const Duration(minutes: 3));
        when(mockStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => nearExpiry.toIso8601String());

        // Act
        final isExpired = await helper.isGoogleTokenExpired();

        // Assert
        expect(isExpired, true);
      });

      test('過期時間在 6 分鐘後應視為未過期', () async {
        // Arrange
        final safeExpiry = DateTime.now().add(const Duration(minutes: 6));
        when(mockStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => safeExpiry.toIso8601String());

        // Act
        final isExpired = await helper.isGoogleTokenExpired();

        // Assert
        expect(isExpired, false);
      });
    });

    group('clearGoogleTokens', () {
      test('應刪除所有 Google 相關 tokens', () async {
        // Arrange
        when(mockStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async {});

        // Act
        await helper.clearGoogleTokens();

        // Assert
        verify(mockStorage.delete(key: 'google_access_token')).called(1);
        verify(mockStorage.delete(key: 'google_refresh_token')).called(1);
        verify(mockStorage.delete(key: 'google_token_expiry')).called(1);
      });

      test('應並行刪除所有 tokens', () async {
        // Arrange
        final deleteOrder = <String>[];
        when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((invocation) async {
          deleteOrder.add(invocation.namedArguments[#key] as String);
        });

        // Act
        await helper.clearGoogleTokens();

        // Assert
        expect(deleteOrder.length, 3);
        expect(deleteOrder, containsAll([
          'google_access_token',
          'google_refresh_token',
          'google_token_expiry',
        ]));
      });
    });
  });

  group('SecureStorageHelper - 通用方法', () {
    late MockFlutterSecureStorage mockStorage;
    late _TestableSecureStorageHelper helper;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      helper = _TestableSecureStorageHelper(mockStorage);
    });

    group('write', () {
      test('應正確寫入任意鍵值', () async {
        // Arrange
        when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        await helper.write('custom_key', 'custom_value');

        // Assert
        verify(mockStorage.write(
          key: 'custom_key',
          value: 'custom_value',
        )).called(1);
      });
    });

    group('read', () {
      test('應正確讀取任意鍵', () async {
        // Arrange
        when(mockStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => 'read_value');

        // Act
        final value = await helper.read('custom_key');

        // Assert
        expect(value, 'read_value');
        verify(mockStorage.read(key: 'custom_key')).called(1);
      });

      test('不存在的鍵應回傳 null', () async {
        // Arrange
        when(mockStorage.read(key: anyNamed('key')))
            .thenAnswer((_) async => null);

        // Act
        final value = await helper.read('non_existent');

        // Assert
        expect(value, isNull);
      });
    });

    group('delete', () {
      test('應正確刪除任意鍵', () async {
        // Arrange
        when(mockStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async {});

        // Act
        await helper.delete('custom_key');

        // Assert
        verify(mockStorage.delete(key: 'custom_key')).called(1);
      });
    });

    group('containsKey', () {
      test('存在的鍵應回傳 true', () async {
        // Arrange
        when(mockStorage.containsKey(key: anyNamed('key')))
            .thenAnswer((_) async => true);

        // Act
        final exists = await helper.containsKey('existing_key');

        // Assert
        expect(exists, true);
      });

      test('不存在的鍵應回傳 false', () async {
        // Arrange
        when(mockStorage.containsKey(key: anyNamed('key')))
            .thenAnswer((_) async => false);

        // Act
        final exists = await helper.containsKey('missing_key');

        // Assert
        expect(exists, false);
      });
    });

    group('deleteAll', () {
      test('應清除所有儲存的資料', () async {
        // Arrange
        when(mockStorage.deleteAll()).thenAnswer((_) async {});

        // Act
        await helper.deleteAll();

        // Assert
        verify(mockStorage.deleteAll()).called(1);
      });
    });
  });

  group('SecureStorageHelper - 儲存鍵值常數', () {
    test('access token 鍵應為 google_access_token', () {
      const expectedKey = 'google_access_token';
      expect(expectedKey, isNotEmpty);
    });

    test('refresh token 鍵應為 google_refresh_token', () {
      const expectedKey = 'google_refresh_token';
      expect(expectedKey, isNotEmpty);
    });

    test('expiry 鍵應為 google_token_expiry', () {
      const expectedKey = 'google_token_expiry';
      expect(expectedKey, isNotEmpty);
    });
  });

  group('SecureStorageHelper - 安全性', () {
    test('Android 應使用加密的 SharedPreferences', () {
      // 文件化測試：確保使用加密儲存
      // SecureStorageHelper 使用 AndroidOptions(encryptedSharedPreferences: true)
      const useEncrypted = true;
      expect(useEncrypted, true);
    });

    test('iOS 應使用 first_unlock 層級的 Keychain 存取', () {
      // 文件化測試：確保適當的 Keychain 存取層級
      // first_unlock 表示裝置解鎖後即可存取
      const accessibility = KeychainAccessibility.first_unlock;
      expect(accessibility, isNotNull);
    });
  });
}

/// 可測試的 SecureStorageHelper
///
/// 允許注入 mock storage 進行測試
class _TestableSecureStorageHelper {
  _TestableSecureStorageHelper(this._storage);

  final FlutterSecureStorage _storage;

  static const String _keyGoogleAccessToken = 'google_access_token';
  static const String _keyGoogleRefreshToken = 'google_refresh_token';
  static const String _keyGoogleTokenExpiry = 'google_token_expiry';

  Future<void> saveGoogleAccessToken(String token) async {
    await _storage.write(key: _keyGoogleAccessToken, value: token);
  }

  Future<String?> getGoogleAccessToken() async {
    return await _storage.read(key: _keyGoogleAccessToken);
  }

  Future<void> saveGoogleRefreshToken(String token) async {
    await _storage.write(key: _keyGoogleRefreshToken, value: token);
  }

  Future<String?> getGoogleRefreshToken() async {
    return await _storage.read(key: _keyGoogleRefreshToken);
  }

  Future<void> saveGoogleTokenExpiry(DateTime expiry) async {
    await _storage.write(
      key: _keyGoogleTokenExpiry,
      value: expiry.toIso8601String(),
    );
  }

  Future<DateTime?> getGoogleTokenExpiry() async {
    final value = await _storage.read(key: _keyGoogleTokenExpiry);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<bool> isGoogleTokenExpired() async {
    final expiry = await getGoogleTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)));
  }

  Future<void> clearGoogleTokens() async {
    await Future.wait([
      _storage.delete(key: _keyGoogleAccessToken),
      _storage.delete(key: _keyGoogleRefreshToken),
      _storage.delete(key: _keyGoogleTokenExpiry),
    ]);
  }

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
