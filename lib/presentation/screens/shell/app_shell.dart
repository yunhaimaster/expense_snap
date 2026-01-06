import 'package:flutter/material.dart';

import '../export/export_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';

/// App 外殼
///
/// 包含 Bottom Navigation Bar 的主要容器
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  // 匯出頁刷新計數器：每次切換到匯出頁時遞增
  int _exportRefreshTrigger = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          ExportScreen(refreshTrigger: _exportRefreshTrigger),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // 切換到匯出頁時觸發刷新
          if (index == 1) {
            _exportRefreshTrigger++;
          }
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首頁',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_download_outlined),
            activeIcon: Icon(Icons.file_download),
            label: '匯出',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
