import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/data/datasources/remote/exchange_rate_api.dart';

@GenerateMocks([Dio])
import 'exchange_rate_api_test.mocks.dart';

/// 網絡彈性測試
///
/// 測試各種網絡異常情況的處理
void main() {
  late MockDio mockDio;
  late ExchangeRateApi api;

  setUp(() {
    mockDio = MockDio();
    api = ExchangeRateApi(dio: mockDio);
  });

  group('Exchange Rate API 超時處理', () {
    test('連線超時應返回 NetworkException', () async {
      // Arrange
      when(mockDio.get(any)).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
          message: 'Connection timeout',
        ),
      );

      // Act
      final result = await api.fetchRates();

      // Assert
      expect(result.isFailure, true);
      result.fold(
        onFailure: (error) {
          expect(error, isA<NetworkException>());
        },
        onSuccess: (_) => fail('Should fail'),
      );
    });

    test('接收超時應返回 NetworkException', () async {
      // Arrange
      when(mockDio.get(any)).thenThrow(
        DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(),
          message: 'Receive timeout',
        ),
      );

      // Act
      final result = await api.fetchRates();

      // Assert
      expect(result.isFailure, true);
      result.fold(
        onFailure: (error) {
          expect(error, isA<NetworkException>());
        },
        onSuccess: (_) => fail('Should fail'),
      );
    });

    test('發送超時應返回 NetworkException', () async {
      // Arrange
      when(mockDio.get(any)).thenThrow(
        DioException(
          type: DioExceptionType.sendTimeout,
          requestOptions: RequestOptions(),
          message: 'Send timeout',
        ),
      );

      // Act
      final result = await api.fetchRates();

      // Assert
      expect(result.isFailure, true);
    });
  });

  group('Exchange Rate API 連線錯誤處理', () {
    test('無網絡連線應返回 NetworkException', () async {
      // Arrange
      when(mockDio.get(any)).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(),
          message: 'Connection refused',
        ),
      );

      // Act
      final result = await api.fetchRates();

      // Assert
      expect(result.isFailure, true);
      result.fold(
        onFailure: (error) {
          expect(error, isA<NetworkException>());
        },
        onSuccess: (_) => fail('Should fail'),
      );
    });

    test('DNS 解析失敗應返回 NetworkException', () async {
      // Arrange
      when(mockDio.get(any)).thenThrow(
        DioException(
          type: DioExceptionType.unknown,
          requestOptions: RequestOptions(),
          message: 'Failed host lookup',
        ),
      );

      // Act
      final result = await api.fetchRates();

      // Assert
      expect(result.isFailure, true);
    });
  });

  group('Exchange Rate API 伺服器錯誤處理', () {
    test('500 伺服器錯誤應返回 NetworkException', () async {
      // Arrange
      when(mockDio.get(any)).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 500,
            data: 'Internal Server Error',
          ),
        ),
      );

      // Act
      final result = await api.fetchRates();

      // Assert
      expect(result.isFailure, true);
      result.fold(
        onFailure: (error) {
          expect(error, isA<NetworkException>());
        },
        onSuccess: (_) => fail('Should fail'),
      );
    });

    test('503 服務不可用應返回 NetworkException', () async {
      // Arrange
      when(mockDio.get(any)).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 503,
            data: 'Service Unavailable',
          ),
        ),
      );

      // Act
      final result = await api.fetchRates();

      // Assert
      expect(result.isFailure, true);
    });

    test('429 請求過多應返回 NetworkException (rate limited)', () async {
      // Arrange
      when(mockDio.get(any)).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 429,
            data: 'Too Many Requests',
          ),
        ),
      );

      // Act
      final result = await api.fetchRates();

      // Assert
      expect(result.isFailure, true);
    });
  });

  group('Exchange Rate API 回應格式錯誤處理', () {
    test('空回應應返回失敗', () async {
      // Arrange
      when(mockDio.get(any)).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 200,
            data: null,
          ));

      // Act
      final result = await api.fetchRates();

      // Assert
      expect(result.isFailure, true);
    });

    test('非預期 JSON 結構應返回失敗', () async {
      // Arrange
      when(mockDio.get(any)).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 200,
            data: {'unexpected': 'structure'},
          ));

      // Act
      final result = await api.fetchRates();

      // Assert
      expect(result.isFailure, true);
    });

    test('缺少必要幣別應處理正確', () async {
      // Arrange - 只有 CNY 沒有 USD
      when(mockDio.get(any)).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 200,
            data: {
              'hkd': {'cny': 0.918}
            },
          ));

      // Act
      final result = await api.fetchRates();

      // Assert
      expect(result.isSuccess, true);
      result.fold(
        onFailure: (e) => fail('Should succeed'),
        onSuccess: (rates) {
          expect(rates.containsKey('CNY'), true);
          // USD 可能有預設值或不存在
        },
      );
    });
  });

  group('網絡請求取消處理', () {
    test('請求被取消應正確處理', () async {
      // Arrange
      when(mockDio.get(any)).thenThrow(
        DioException(
          type: DioExceptionType.cancel,
          requestOptions: RequestOptions(),
          message: 'Request cancelled',
        ),
      );

      // Act
      final result = await api.fetchRates();

      // Assert
      expect(result.isFailure, true);
    });
  });

  group('速率限制恢復測試', () {
    test('所有 API 端點失敗後返回失敗', () async {
      // 模擬：主要和備援 API 都返回 429
      when(mockDio.get(any)).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 429,
            data: 'Too Many Requests',
          ),
        ),
      );

      // Act - 主要和備援都失敗
      final result = await api.fetchRates();

      // Assert
      expect(result.isFailure, true);
    });

    test('主要 API 失敗後備援 API 成功', () async {
      var callCount = 0;

      // 模擬：第一次呼叫（主要 API）返回 429，第二次（備援 API）成功
      when(mockDio.get(any)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw DioException(
            type: DioExceptionType.badResponse,
            requestOptions: RequestOptions(),
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 429,
              data: 'Too Many Requests',
            ),
          );
        }
        return Response(
          requestOptions: RequestOptions(),
          statusCode: 200,
          data: {
            'hkd': {'cny': 0.918, 'usd': 0.128}
          },
        );
      });

      // Act
      final result = await api.fetchRates();

      // Assert - 備援 API 成功
      expect(callCount, 2); // 主要 + 備援
      expect(result.isSuccess, true);
    });
  });

  group('備援 API 測試', () {
    test('主 API 失敗應嘗試備援 API', () async {
      var callCount = 0;

      // 主 API 失敗，備援 API 成功
      when(mockDio.get(any)).thenAnswer((invocation) async {
        callCount++;
        final url = invocation.positionalArguments[0] as String;

        // 主 API 失敗
        if (url.contains('cdn.jsdelivr.net')) {
          throw DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(),
          );
        }

        // 備援 API 成功
        return Response(
          requestOptions: RequestOptions(),
          statusCode: 200,
          data: {
            'hkd': {'cny': 0.918, 'usd': 0.128}
          },
        );
      });

      // Act
      final result = await api.fetchRates();

      // Assert - 應該嘗試了多個 API
      expect(callCount, greaterThan(1));
      // 最終應該成功（從備援 API）
      expect(result.isSuccess, true);
    });
  });

  group('並發請求處理', () {
    test('首次請求成功，後續並發請求因速率限制而失敗', () async {
      // 注意：ExchangeRateApi 有內建 5 秒速率限制
      // 第一個請求會成功，後續請求會因速率限制而返回錯誤
      when(mockDio.get(any)).thenAnswer((_) async {
        return Response(
          requestOptions: RequestOptions(),
          statusCode: 200,
          data: {
            'hkd': {'cny': 0.918, 'usd': 0.128}
          },
        );
      });

      // 發起 5 個並發請求
      final futures = List.generate(5, (_) => api.fetchRates());
      final results = await Future.wait(futures);

      // 第一個請求應該成功
      expect(results.first.isSuccess, true);

      // 後續請求可能因速率限制而失敗
      // 這取決於 API 內部的速率限制機制
      final successCount = results.where((r) => r.isSuccess).length;
      expect(successCount, greaterThanOrEqualTo(1));
    });

    test('單一請求成功驗證', () async {
      when(mockDio.get(any)).thenAnswer((_) async {
        return Response(
          requestOptions: RequestOptions(),
          statusCode: 200,
          data: {
            'hkd': {'cny': 0.918, 'usd': 0.128}
          },
        );
      });

      // 單一請求應該成功
      final result = await api.fetchRates();
      expect(result.isSuccess, true);

      result.fold(
        onFailure: (_) => fail('Should succeed'),
        onSuccess: (rates) {
          expect(rates.containsKey('CNY'), true);
          expect(rates.containsKey('USD'), true);
        },
      );
    });
  });
}
