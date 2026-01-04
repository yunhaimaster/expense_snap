import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_snap/presentation/providers/exchange_rate_provider.dart';
import 'package:expense_snap/data/repositories/exchange_rate_repository.dart';
import 'package:expense_snap/core/errors/result.dart';
import 'package:expense_snap/core/errors/app_exception.dart';
import 'package:expense_snap/core/constants/currency_constants.dart';

@GenerateMocks([ExchangeRateRepository])
import 'exchange_rate_provider_test.mocks.dart';

void main() {
  final testRateInfo = ExchangeRateInfo(
    rateToHkd: 7800000,
    source: ExchangeRateSource.auto,
    fetchedAt: DateTime.now(),
  );

  final allRates = <String, ExchangeRateInfo>{
    'HKD': ExchangeRateInfo(
      rateToHkd: CurrencyConstants.ratePrecision,
      source: ExchangeRateSource.auto,
      fetchedAt: DateTime.now(),
    ),
    'USD': testRateInfo,
    'CNY': ExchangeRateInfo(
      rateToHkd: 1089000,
      source: ExchangeRateSource.auto,
      fetchedAt: DateTime.now(),
    ),
  };

  // 註冊 dummy values（Mockito 需要）
  setUpAll(() {
    provideDummy<Result<ExchangeRateInfo>>(Result.success(testRateInfo));
    provideDummy<Result<Map<String, ExchangeRateInfo>>>(Result.success(allRates));
  });

  late MockExchangeRateRepository mockRepository;
  late ExchangeRateProvider provider;

  setUp(() {
    mockRepository = MockExchangeRateRepository();

    // 預設 stub
    when(mockRepository.canRefresh).thenReturn(true);
    when(mockRepository.secondsUntilRefresh).thenReturn(0);
    when(mockRepository.getRate(any))
        .thenAnswer((_) async => Result.success(testRateInfo));
    when(mockRepository.getAllRates())
        .thenAnswer((_) async => Result.success(allRates));
    when(mockRepository.refreshRates())
        .thenAnswer((_) async => Result.success(allRates));

    provider = ExchangeRateProvider(repository: mockRepository);
  });

  group('ExchangeRateProvider 初始化', () {
    test('初始狀態應為空', () {
      expect(provider.rates, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });
  });

  group('ExchangeRateProvider.loadRate', () {
    test('HKD 應返回固定 1:1 匯率', () async {
      final result = await provider.loadRate('HKD');

      expect(result, isNotNull);
      expect(result!.rateToHkd, CurrencyConstants.ratePrecision);
      expect(result.source, ExchangeRateSource.auto);
      // 不應調用 repository
      verifyNever(mockRepository.getRate('HKD'));
    });

    test('成功載入 USD 匯率', () async {
      final result = await provider.loadRate('USD');

      expect(result, isNotNull);
      expect(result!.rateToHkd, 7800000);
      expect(provider.getRate('USD'), isNotNull);
      expect(provider.isLoading, false);
    });

    test('載入失敗應設定錯誤', () async {
      when(mockRepository.getRate('USD')).thenAnswer(
        (_) async => Result.failure(const NetworkException('網絡錯誤')),
      );

      final result = await provider.loadRate('USD');

      expect(result, isNull);
      expect(provider.error, isA<NetworkException>());
    });

    test('5 分鐘內應使用快取（避免重複請求）', () async {
      // 第一次載入
      await provider.loadRate('USD');

      // 第二次載入（應使用快取）
      await provider.loadRate('USD');

      // 只應調用一次
      verify(mockRepository.getRate('USD')).called(1);
    });
  });

  group('ExchangeRateProvider.loadAllRates', () {
    test('成功載入所有匯率', () async {
      await provider.loadAllRates();

      expect(provider.rates.length, 3);
      expect(provider.getRate('HKD'), isNotNull);
      expect(provider.getRate('USD'), isNotNull);
      expect(provider.getRate('CNY'), isNotNull);
      expect(provider.isLoading, false);
    });

    test('載入失敗應設定錯誤', () async {
      when(mockRepository.getAllRates()).thenAnswer(
        (_) async => Result.failure(const NetworkException('網絡錯誤')),
      );

      await provider.loadAllRates();

      expect(provider.error, isA<NetworkException>());
    });
  });

  group('ExchangeRateProvider.refreshRates', () {
    test('成功重新整理匯率', () async {
      final success = await provider.refreshRates();

      expect(success, true);
      expect(provider.rates.length, 3);
    });

    test('冷卻期內應拒絕重新整理', () async {
      when(mockRepository.canRefresh).thenReturn(false);
      when(mockRepository.secondsUntilRefresh).thenReturn(25);

      final success = await provider.refreshRates();

      expect(success, false);
      expect(provider.error, isA<NetworkException>());
      expect(provider.error!.message, contains('25'));
    });

    test('重新整理失敗應設定錯誤', () async {
      when(mockRepository.refreshRates()).thenAnswer(
        (_) async => Result.failure(const NetworkException('API 錯誤')),
      );

      final success = await provider.refreshRates();

      expect(success, false);
      expect(provider.error, isA<NetworkException>());
    });
  });

  group('ExchangeRateProvider.canRefresh', () {
    test('應代理 repository.canRefresh', () {
      when(mockRepository.canRefresh).thenReturn(true);
      expect(provider.canRefresh, true);

      when(mockRepository.canRefresh).thenReturn(false);
      expect(provider.canRefresh, false);
    });
  });

  group('ExchangeRateProvider.secondsUntilRefresh', () {
    test('應代理 repository.secondsUntilRefresh', () {
      when(mockRepository.secondsUntilRefresh).thenReturn(15);
      expect(provider.secondsUntilRefresh, 15);
    });
  });

  group('ExchangeRateProvider.clearError', () {
    test('應清除錯誤狀態', () async {
      // 先觸發錯誤
      when(mockRepository.canRefresh).thenReturn(false);
      when(mockRepository.secondsUntilRefresh).thenReturn(10);
      await provider.refreshRates();
      expect(provider.error, isNotNull);

      provider.clearError();

      expect(provider.error, isNull);
    });
  });

  group('ExchangeRateInfo', () {
    test('formattedRate 應正確格式化', () {
      final info = ExchangeRateInfo(
        rateToHkd: 7800000,
        source: ExchangeRateSource.auto,
        fetchedAt: DateTime.now(),
      );

      // 7800000 / 1000000 = 7.8
      expect(info.formattedRate, contains('7.8'));
    });
  });
}
