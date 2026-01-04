import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_snap/presentation/providers/connectivity_provider.dart';

@GenerateMocks([Connectivity])
import 'connectivity_provider_test.mocks.dart';

void main() {
  late MockConnectivity mockConnectivity;
  late StreamController<List<ConnectivityResult>> streamController;

  setUp(() {
    mockConnectivity = MockConnectivity();
    streamController = StreamController<List<ConnectivityResult>>.broadcast();

    // 預設 stub
    when(mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => streamController.stream);
  });

  tearDown(() {
    streamController.close();
  });

  group('ConnectivityProvider 初始化', () {
    test('初始狀態應為已連線', () async {
      final provider = ConnectivityProvider(connectivity: mockConnectivity);

      // 等待初始化完成
      await Future.delayed(Duration.zero);

      expect(provider.isConnected, true);
      expect(provider.isOffline, false);
      expect(provider.connectionTypes, contains(ConnectivityResult.wifi));

      provider.dispose();
    });

    test('初始化時無網絡應顯示離線', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      final provider = ConnectivityProvider(connectivity: mockConnectivity);
      await Future.delayed(Duration.zero);

      expect(provider.isConnected, false);
      expect(provider.isOffline, true);

      provider.dispose();
    });
  });

  group('ConnectivityProvider.isWifi', () {
    test('使用 WiFi 時應為 true', () async {
      final provider = ConnectivityProvider(connectivity: mockConnectivity);
      await Future.delayed(Duration.zero);

      expect(provider.isWifi, true);
      expect(provider.isMobile, false);

      provider.dispose();
    });
  });

  group('ConnectivityProvider.isMobile', () {
    test('使用行動網絡時應為 true', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.mobile]);

      final provider = ConnectivityProvider(connectivity: mockConnectivity);
      await Future.delayed(Duration.zero);

      expect(provider.isMobile, true);
      expect(provider.isWifi, false);

      provider.dispose();
    });
  });

  group('ConnectivityProvider 狀態監聽', () {
    test('網絡狀態變化時應更新狀態', () async {
      final provider = ConnectivityProvider(connectivity: mockConnectivity);
      await Future.delayed(Duration.zero);

      expect(provider.isConnected, true);

      // 模擬網絡斷開
      streamController.add([ConnectivityResult.none]);
      await Future.delayed(Duration.zero);

      expect(provider.isConnected, false);
      expect(provider.isOffline, true);

      // 模擬網絡恢復
      streamController.add([ConnectivityResult.wifi]);
      await Future.delayed(Duration.zero);

      expect(provider.isConnected, true);
      expect(provider.isOffline, false);

      provider.dispose();
    });

    test('多種連線類型應正確識別', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [
                ConnectivityResult.wifi,
                ConnectivityResult.mobile,
              ]);

      final provider = ConnectivityProvider(connectivity: mockConnectivity);
      await Future.delayed(Duration.zero);

      expect(provider.isConnected, true);
      expect(provider.isWifi, true);
      expect(provider.isMobile, true);

      provider.dispose();
    });
  });

  group('ConnectivityProvider.checkConnectivity', () {
    test('手動檢查應更新狀態', () async {
      final provider = ConnectivityProvider(connectivity: mockConnectivity);
      await Future.delayed(Duration.zero);

      // 模擬狀態變化
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.mobile]);

      final isConnected = await provider.checkConnectivity();

      expect(isConnected, true);
      expect(provider.isMobile, true);

      provider.dispose();
    });

    test('檢查失敗應返回當前狀態', () async {
      final provider = ConnectivityProvider(connectivity: mockConnectivity);
      await Future.delayed(Duration.zero);

      when(mockConnectivity.checkConnectivity())
          .thenThrow(Exception('檢查失敗'));

      final isConnected = await provider.checkConnectivity();

      // 應返回之前的狀態
      expect(isConnected, true);

      provider.dispose();
    });
  });

  group('ConnectivityProvider.dispose', () {
    test('dispose 應取消訂閱', () async {
      final provider = ConnectivityProvider(connectivity: mockConnectivity);
      await Future.delayed(Duration.zero);

      provider.dispose();

      // 之後的狀態變化不應影響（不會拋出錯誤）
      streamController.add([ConnectivityResult.none]);
      await Future.delayed(Duration.zero);

      // 測試通過即表示沒有錯誤
    });
  });

  group('ConnectivityProvider 錯誤處理', () {
    test('初始化檢查失敗應保持預設狀態', () async {
      when(mockConnectivity.checkConnectivity())
          .thenThrow(Exception('初始化失敗'));

      final provider = ConnectivityProvider(connectivity: mockConnectivity);
      await Future.delayed(Duration.zero);

      // 預設為已連線
      expect(provider.isConnected, true);

      provider.dispose();
    });
  });
}
