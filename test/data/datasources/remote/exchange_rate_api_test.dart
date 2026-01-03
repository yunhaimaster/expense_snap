import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:expense_snap/core/constants/currency_constants.dart';
import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/data/datasources/remote/exchange_rate_api.dart';

@GenerateMocks([Dio])
import 'exchange_rate_api_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late ExchangeRateApi api;

  setUp(() {
    mockDio = MockDio();
    api = ExchangeRateApi(dio: mockDio);
  });

  group('ExchangeRateApi', () {
    group('fetchRates', () {
      test('成功從主要 API 取得匯率', () async {
        // Arrange
        final responseData = {
          'hkd': {
            'cny': 0.918, // 1 HKD = 0.918 CNY
            'usd': 0.128, // 1 HKD = 0.128 USD
          }
        };

        when(mockDio.get(any)).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(),
              statusCode: 200,
              data: responseData,
            ));

        // Act
        final result = await api.fetchRates();

        // Assert
        expect(result.isSuccess, true);
        result.fold(
          onFailure: (e) => fail('Should succeed'),
          onSuccess: (rates) {
            // CNY: 1/0.918 ≈ 1.089 → 1089000
            expect(rates['CNY'], isNotNull);
            expect(rates['CNY']! > 1000000, true); // > 1 HKD per CNY

            // USD: 1/0.128 ≈ 7.8 → 7800000
            expect(rates['USD'], isNotNull);
            expect(rates['USD']! > 7000000, true); // > 7 HKD per USD

            // HKD 固定 1:1
            expect(rates['HKD'], CurrencyConstants.ratePrecision);
          },
        );
      });

      test('主要 API 失敗時嘗試備用 API', () async {
        // Arrange
        var callCount = 0;
        when(mockDio.get(any)).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            // 主要 API 失敗
            throw DioException(
              requestOptions: RequestOptions(),
              type: DioExceptionType.connectionTimeout,
            );
          } else {
            // 備用 API 成功
            return Response(
              requestOptions: RequestOptions(),
              statusCode: 200,
              data: {
                'hkd': {
                  'cny': 0.92,
                  'usd': 0.13,
                }
              },
            );
          }
        });

        // Act
        final result = await api.fetchRates();

        // Assert
        expect(result.isSuccess, true);
        expect(callCount, 2); // 呼叫了兩次
      });

      test('兩個 API 都失敗時回傳錯誤', () async {
        // Arrange
        when(mockDio.get(any)).thenThrow(DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ));

        // Act
        final result = await api.fetchRates();

        // Assert
        expect(result.isFailure, true);
        result.fold(
          onFailure: (e) {
            expect(e, isA<NetworkException>());
          },
          onSuccess: (_) => fail('Should fail'),
        );
      });

      test('伺服器錯誤時回傳錯誤', () async {
        // Arrange
        when(mockDio.get(any)).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(),
              statusCode: 500,
              data: null,
            ));

        // Act
        final result = await api.fetchRates();

        // Assert
        expect(result.isFailure, true);
        result.fold(
          onFailure: (e) {
            expect(e, isA<NetworkException>());
          },
          onSuccess: (_) => fail('Should fail'),
        );
      });

      test('回應格式錯誤時回傳錯誤', () async {
        // Arrange
        when(mockDio.get(any)).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(),
              statusCode: 200,
              data: {'invalid': 'format'}, // 缺少 'hkd' 欄位
            ));

        // Act
        final result = await api.fetchRates();

        // Assert
        expect(result.isFailure, true);
        result.fold(
          onFailure: (e) {
            expect(e, isA<NetworkException>());
            // 錯誤訊息應包含 'Missing HKD' 或 'Invalid'（更具體的錯誤說明）
            expect(
              e.message.contains('Missing HKD') || e.message.contains('Invalid'),
              true,
              reason: 'Error message should indicate missing/invalid response',
            );
          },
          onSuccess: (_) => fail('Should fail'),
        );
      });

      test('逾時時回傳 timeout 錯誤', () async {
        // Arrange
        when(mockDio.get(any)).thenThrow(DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.receiveTimeout,
        ));

        // Act
        final result = await api.fetchRates();

        // Assert
        expect(result.isFailure, true);
        result.fold(
          onFailure: (e) {
            expect(e, isA<NetworkException>());
            expect(e.code, 'TIMEOUT');
          },
          onSuccess: (_) => fail('Should fail'),
        );
      });
    });
  });
}
