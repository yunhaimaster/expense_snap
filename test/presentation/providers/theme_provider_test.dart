import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/presentation/providers/theme_provider.dart';
import 'package:flutter/material.dart';

void main() {
  group('ThemeProvider', () {
    group('初始狀態', () {
      test('預設主題模式為 system', () {
        final provider = ThemeProvider();
        expect(provider.themeMode, AppThemeMode.system);
      });

      test('預設減少動畫為 false', () {
        final provider = ThemeProvider();
        expect(provider.reduceMotion, false);
      });

      test('materialThemeMode 根據 themeMode 變化', () {
        final provider = ThemeProvider();
        // 預設為 system
        expect(provider.materialThemeMode, ThemeMode.system);
      });
    });

    group('主題模式切換', () {
      test('setThemeMode 設定為 light', () async {
        final provider = ThemeProvider();
        await provider.setThemeMode(AppThemeMode.light);
        expect(provider.themeMode, AppThemeMode.light);
        expect(provider.materialThemeMode, ThemeMode.light);
      });

      test('setThemeMode 設定為 dark', () async {
        final provider = ThemeProvider();
        await provider.setThemeMode(AppThemeMode.dark);
        expect(provider.themeMode, AppThemeMode.dark);
        expect(provider.materialThemeMode, ThemeMode.dark);
      });

      test('setThemeMode 設定為 system', () async {
        final provider = ThemeProvider();
        await provider.setThemeMode(AppThemeMode.dark);
        await provider.setThemeMode(AppThemeMode.system);
        expect(provider.themeMode, AppThemeMode.system);
        expect(provider.materialThemeMode, ThemeMode.system);
      });

      test('相同模式不觸發通知', () async {
        final provider = ThemeProvider();
        await provider.setThemeMode(AppThemeMode.light);

        var notified = false;
        provider.addListener(() => notified = true);

        await provider.setThemeMode(AppThemeMode.light);
        expect(notified, false);
      });
    });

    group('減少動畫', () {
      test('setReduceMotion 設定為 true', () async {
        final provider = ThemeProvider();
        await provider.setReduceMotion(true);
        expect(provider.reduceMotion, true);
      });

      test('setReduceMotion 設定為 false', () async {
        final provider = ThemeProvider();
        await provider.setReduceMotion(true);
        await provider.setReduceMotion(false);
        expect(provider.reduceMotion, false);
      });

      test('相同值不觸發通知', () async {
        final provider = ThemeProvider();

        var notified = false;
        provider.addListener(() => notified = true);

        await provider.setReduceMotion(false);
        expect(notified, false);
      });
    });

    group('toggleTheme', () {
      test('從 light 切換到 dark', () async {
        final provider = ThemeProvider();
        await provider.setThemeMode(AppThemeMode.light);

        await provider.toggleTheme();
        expect(provider.themeMode, AppThemeMode.dark);
      });

      test('從 dark 切換到 light', () async {
        final provider = ThemeProvider();
        await provider.setThemeMode(AppThemeMode.dark);

        await provider.toggleTheme();
        expect(provider.themeMode, AppThemeMode.light);
      });
    });

    group('brightness', () {
      test('light 模式回傳 Brightness.light', () async {
        final provider = ThemeProvider();
        await provider.setThemeMode(AppThemeMode.light);
        expect(provider.brightness, Brightness.light);
      });

      test('dark 模式回傳 Brightness.dark', () async {
        final provider = ThemeProvider();
        await provider.setThemeMode(AppThemeMode.dark);
        expect(provider.brightness, Brightness.dark);
      });

      test('isDarkMode 在 dark 模式為 true', () async {
        final provider = ThemeProvider();
        await provider.setThemeMode(AppThemeMode.dark);
        expect(provider.isDarkMode, true);
      });

      test('isDarkMode 在 light 模式為 false', () async {
        final provider = ThemeProvider();
        await provider.setThemeMode(AppThemeMode.light);
        expect(provider.isDarkMode, false);
      });
    });
  });
}
