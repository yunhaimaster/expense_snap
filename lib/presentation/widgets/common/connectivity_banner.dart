import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/connectivity_provider.dart';

/// 離線狀態橫幅
///
/// 當偵測到無網絡連線時顯示提示
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Selector 只在 isConnected 變化時重建
    return Selector<ConnectivityProvider, bool>(
      selector: (_, p) => p.isConnected,
      builder: (context, isConnected, child) {
        if (isConnected) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.warning,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                '離線模式 - 匯率可能不是最新',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 帶動畫的離線橫幅
///
/// 網絡恢復時會自動滑出
class AnimatedConnectivityBanner extends StatelessWidget {
  const AnimatedConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Selector 只在 isOffline 變化時重建
    return Selector<ConnectivityProvider, bool>(
      selector: (_, p) => p.isOffline,
      builder: (context, isOffline, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isOffline ? 40 : 0,
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isOffline ? 1.0 : 0.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.warning,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '離線模式 - 匯率可能不是最新',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
