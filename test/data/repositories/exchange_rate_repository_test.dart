import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:expense_snap/core/constants/currency_constants.dart';
import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/data/datasources/local/database_helper.dart';
import 'package:expense_snap/data/datasources/remote/exchange_rate_api.dart';
import 'package:expense_snap/data/repositories/exchange_rate_repository.dart';

@GenerateMocks([DatabaseHelper, ExchangeRateApi])
import 'exchange_rate_repository_test.mocks.dart';

void main() {
  late MockDatabaseHelper mockDb;
  late MockExchangeRateApi mockApi;
  late ExchangeRateRepository repository;

  setUpAll(() {
    // 提供 Result 類型的 dummy 值
    provideDummy<Result<Map<String, int>>>(
      Result.success(<String, int>{}),
    );
  });

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockApi = MockExchangeRateApi();
    repository = ExchangeRateRepository(
      databaseHelper: mockDb,
      api: mockApi,
    );
  });

  group('ExchangeRateRepository', () {
    group('getRate', () {
      test('HKD 固定回傳 1:1 匯率', () async {
        // Act
        final result = await repository.getRate('HKD');

        // Assert
        expect(result.isSuccess, true);
        result.fold(
          onFailure: (e) => fail('Should succeed'),
          onSuccess: (info) {
            expect(info.rateToHkd, CurrencyConstants.ratePrecision);
            expect(info.source, ExchangeRateSource.auto);
          },
        );
      });

      test('快取有效時直接回傳', () async {
        // Arrange
        final cachedData = {
          'currency': 'CNY',
          'rate_to_hkd': 1100000,
          'fetched_at': DateTime.now().toIso8601String(),
          'source': 'primary',
        };
        when(mockDb.getExchangeRateCache('CNY'))
            .thenAnswer((_) async => cachedData);

        // Act
        final result = await repository.getRate('CNY');

        // Assert
        expect(result.isSuccess, true);
        result.fold(
          onFailure: (e) => fail('Should succeed'),
          onSuccess: (info) {
            expect(info.rateToHkd, 1100000);
            expect(info.source, ExchangeRateSource.auto);
          },
        );
        verifyNever(mockApi.fetchRates());
      });

      test('快取過期時從 API 取得新匯率', () async {
        // Arrange
        final expiredCache = {
          'currency': 'CNY',
          'rate_to_hkd': 1050000,
          'fetched_at':
              DateTime.now().subtract(const Duration(hours: 25)).toIso8601String(),
          'source': 'primary',
        };
        when(mockDb.getExchangeRateCache('CNY'))
            .thenAnswer((_) async => expiredCache);

        final newRates = {'CNY': 1100000, 'USD': 7800000};
        when(mockApi.fetchRates())
            .thenAnswer((_) async => Result.success(newRates));
        when(mockDb.upsertExchangeRateCache(any)).thenAnswer((_) async {});

        // Act
        final result = await repository.getRate('CNY');

        // Assert
        expect(result.isSuccess, true);
        result.fold(
          onFailure: (e) => fail('Should succeed'),
          onSuccess: (info) {
            expect(info.rateToHkd, 1100000);
            expect(info.source, ExchangeRateSource.auto);
          },
        );
        verify(mockApi.fetchRates()).called(1);
      });

      test('API 失敗時使用過期快取（offline）', () async {
        // Arrange
        final expiredCache = {
          'currency': 'CNY',
          'rate_to_hkd': 1050000,
          'fetched_at':
              DateTime.now().subtract(const Duration(hours: 25)).toIso8601String(),
          'source': 'primary',
        };
        when(mockDb.getExchangeRateCache('CNY'))
            .thenAnswer((_) async => expiredCache);

        when(mockApi.fetchRates()).thenAnswer(
            (_) async => Result.failure(NetworkException.noConnection()));

        // Act
        final result = await repository.getRate('CNY');

        // Assert
        expect(result.isSuccess, true);
        result.fold(
          onFailure: (e) => fail('Should succeed'),
          onSuccess: (info) {
            expect(info.rateToHkd, 1050000);
            expect(info.source, ExchangeRateSource.offline);
          },
        );
      });

      test('API 失敗且無快取時使用預設匯率', () async {
        // Arrange
        when(mockDb.getExchangeRateCache('CNY')).thenAnswer((_) async => null);

        when(mockApi.fetchRates()).thenAnswer(
            (_) async => Result.failure(NetworkException.noConnection()));

        // Act
        final result = await repository.getRate('CNY');

        // Assert
        expect(result.isSuccess, true);
        result.fold(
          onFailure: (e) => fail('Should succeed'),
          onSuccess: (info) {
            expect(info.rateToHkd, CurrencyConstants.defaultRatesToHkd['CNY']);
            expect(info.source, ExchangeRateSource.defaultRate);
          },
        );
      });
    });

    group('refreshRates', () {
      test('成功重新整理時更新快取', () async {
        // Arrange
        final newRates = {
          'CNY': 1100000,
          'USD': 7850000,
          'HKD': CurrencyConstants.ratePrecision,
        };
        when(mockApi.fetchRates())
            .thenAnswer((_) async => Result.success(newRates));
        when(mockDb.upsertExchangeRateCache(any)).thenAnswer((_) async {});

        // Act
        final result = await repository.refreshRates();

        // Assert
        expect(result.isSuccess, true);
        result.fold(
          onFailure: (e) => fail('Should succeed'),
          onSuccess: (info) {
            expect(info.length, 3);
            expect(info['CNY']!.rateToHkd, 1100000);
            expect(info['USD']!.rateToHkd, 7850000);
          },
        );

        verify(mockDb.upsertExchangeRateCache(any)).called(3);
      });

      test('API 失敗時回傳錯誤', () async {
        // Arrange
        when(mockApi.fetchRates())
            .thenAnswer((_) async => Result.failure(NetworkException.timeout()));

        // Act
        final result = await repository.refreshRates();

        // Assert
        expect(result.isFailure, true);
        result.fold(
          onFailure: (e) {
            expect(e, isA<NetworkException>());
          },
          onSuccess: (_) => fail('Should fail'),
        );
      });

      test('30 秒冷卻期內不能重新整理', () async {
        // Arrange - 先成功一次
        final newRates = {'CNY': 1100000};
        when(mockApi.fetchRates())
            .thenAnswer((_) async => Result.success(newRates));
        when(mockDb.upsertExchangeRateCache(any)).thenAnswer((_) async {});

        await repository.refreshRates();

        // Act - 立即再次請求
        final result = await repository.refreshRates();

        // Assert
        expect(result.isFailure, true);
        result.fold(
          onFailure: (e) {
            expect(e.code, 'COOLDOWN');
          },
          onSuccess: (_) => fail('Should fail with cooldown'),
        );

        // API 只被呼叫一次
        verify(mockApi.fetchRates()).called(1);
      });
    });

    group('forceRefresh', () {
      test('forceRefresh 繞過冷卻期', () async {
        // Arrange - 先成功一次進入冷卻期
        final newRates = {'CNY': 1100000, 'USD': 7850000};
        when(mockApi.fetchRates())
            .thenAnswer((_) async => Result.success(newRates));
        when(mockDb.upsertExchangeRateCache(any)).thenAnswer((_) async {});

        await repository.refreshRates(); // 進入冷卻期
        expect(repository.canRefresh, false);

        // Act - 使用 forceRefresh
        final result = await repository.refreshRates(forceRefresh: true);

        // Assert - 應該成功
        expect(result.isSuccess, true);
        // API 被呼叫兩次
        verify(mockApi.fetchRates()).called(2);
      });

      test('forceRefresh 失敗時正確傳遞錯誤', () async {
        // Arrange
        when(mockApi.fetchRates())
            .thenAnswer((_) async => Result.failure(NetworkException.timeout()));

        // Act
        final result = await repository.refreshRates(forceRefresh: true);

        // Assert
        expect(result.isFailure, true);
        result.fold(
          onFailure: (e) {
            expect(e, isA<NetworkException>());
          },
          onSuccess: (_) => fail('Should fail'),
        );
      });
    });

    group('invalidateCache', () {
      test('清除快取後可立即重新整理', () async {
        // Arrange - 先成功一次進入冷卻期
        final newRates = {'CNY': 1100000};
        when(mockApi.fetchRates())
            .thenAnswer((_) async => Result.success(newRates));
        when(mockDb.upsertExchangeRateCache(any)).thenAnswer((_) async {});
        when(mockDb.clearExchangeRateCache()).thenAnswer((_) async {});

        await repository.refreshRates();
        expect(repository.canRefresh, false);

        // Act
        await repository.invalidateCache();

        // Assert
        expect(repository.canRefresh, true);
        verify(mockDb.clearExchangeRateCache()).called(1);
      });
    });

    group('canRefresh', () {
      test('初始狀態可以重新整理', () {
        expect(repository.canRefresh, true);
      });

      test('重新整理後進入冷卻期', () async {
        // Arrange
        final newRates = {'CNY': 1100000};
        when(mockApi.fetchRates())
            .thenAnswer((_) async => Result.success(newRates));
        when(mockDb.upsertExchangeRateCache(any)).thenAnswer((_) async {});

        // Act
        await repository.refreshRates();

        // Assert
        expect(repository.canRefresh, false);
        expect(repository.secondsUntilRefresh, greaterThan(0));
      });
    });

    group('getAllRates', () {
      test('回傳所有支援幣種的匯率', () async {
        // Arrange
        for (final currency in CurrencyConstants.supportedCurrencies) {
          if (currency == 'HKD') continue;
          when(mockDb.getExchangeRateCache(currency))
              .thenAnswer((_) async => null);
        }

        when(mockApi.fetchRates()).thenAnswer(
            (_) async => Result.failure(NetworkException.noConnection()));

        // Act
        final result = await repository.getAllRates();

        // Assert
        expect(result.isSuccess, true);
        result.fold(
          onFailure: (e) => fail('Should succeed'),
          onSuccess: (rates) {
            // 確保所有支援幣種都有匯率
            for (final currency in CurrencyConstants.supportedCurrencies) {
              expect(rates.containsKey(currency), true);
            }
          },
        );
      });
    });
  });
}
