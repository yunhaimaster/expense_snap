import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/core/theme/app_colors.dart';
import 'package:expense_snap/core/theme/app_theme.dart';

void main() {
  group('Dark Theme 測試', () {
    group('AppColors.dark', () {
      test('主色調存在', () {
        const dark = AppColors.dark;
        expect(dark.primary, isNotNull);
        expect(dark.primaryLight, isNotNull);
        expect(dark.primaryDark, isNotNull);
      });

      test('輔助色存在', () {
        const dark = AppColors.dark;
        expect(dark.secondary, isNotNull);
        expect(dark.secondaryLight, isNotNull);
        expect(dark.secondaryDark, isNotNull);
      });

      test('功能色存在', () {
        const dark = AppColors.dark;
        expect(dark.error, isNotNull);
        expect(dark.errorLight, isNotNull);
        expect(dark.warning, isNotNull);
        expect(dark.warningLight, isNotNull);
        expect(dark.success, isNotNull);
        expect(dark.successLight, isNotNull);
        expect(dark.info, isNotNull);
        expect(dark.infoLight, isNotNull);
      });

      test('中性色存在', () {
        const dark = AppColors.dark;
        expect(dark.background, isNotNull);
        expect(dark.surface, isNotNull);
        expect(dark.surfaceSecondary, isNotNull);
        expect(dark.divider, isNotNull);
      });

      test('文字色存在', () {
        const dark = AppColors.dark;
        expect(dark.textPrimary, isNotNull);
        expect(dark.textSecondary, isNotNull);
        expect(dark.textTertiary, isNotNull);
        expect(dark.textHint, isNotNull);
        expect(dark.textOnPrimary, isNotNull);
      });

      test('匯率來源色存在', () {
        const dark = AppColors.dark;
        expect(dark.rateAuto, isNotNull);
        expect(dark.rateOffline, isNotNull);
        expect(dark.rateDefault, isNotNull);
        expect(dark.rateManual, isNotNull);
      });

      test('Skeleton 色彩存在', () {
        const dark = AppColors.dark;
        expect(dark.skeletonBase, isNotNull);
        expect(dark.skeletonHighlight, isNotNull);
      });

      test('深色背景色彩較深', () {
        const dark = AppColors.dark;
        // 深色主題背景應該較暗
        expect(dark.background.computeLuminance(), lessThan(0.1));
        expect(dark.surface.computeLuminance(), lessThan(0.1));
      });

      test('深色文字色對比足夠', () {
        const dark = AppColors.dark;
        // 深色主題的主要文字應該較亮
        expect(dark.textPrimary.computeLuminance(), greaterThan(0.7));
        expect(dark.textSecondary.computeLuminance(), greaterThan(0.4));
      });
    });

    group('AppTheme.dark', () {
      test('建立正確的深色主題', () {
        final theme = AppTheme.dark;
        expect(theme.brightness, Brightness.dark);
      });

      test('ColorScheme 設定正確', () {
        final theme = AppTheme.dark;
        expect(theme.colorScheme.brightness, Brightness.dark);
        expect(theme.colorScheme.primary, isNotNull);
        expect(theme.colorScheme.secondary, isNotNull);
        expect(theme.colorScheme.error, isNotNull);
      });

      test('背景色設定正確', () {
        final theme = AppTheme.dark;
        expect(theme.scaffoldBackgroundColor, AppColors.dark.background);
      });

      test('AppBar 主題設定正確', () {
        final theme = AppTheme.dark;
        expect(theme.appBarTheme.backgroundColor, AppColors.dark.surface);
        expect(theme.appBarTheme.foregroundColor, AppColors.dark.textPrimary);
      });

      test('卡片主題設定正確', () {
        final theme = AppTheme.dark;
        expect(theme.cardTheme.color, AppColors.dark.surface);
      });

      test('輸入框主題設定正確', () {
        final theme = AppTheme.dark;
        expect(theme.inputDecorationTheme.fillColor, AppColors.dark.surfaceSecondary);
      });

      test('文字主題設定正確', () {
        final theme = AppTheme.dark;
        final textTheme = theme.textTheme;

        expect(textTheme.displayLarge?.color, AppColors.dark.textPrimary);
        expect(textTheme.bodyLarge?.color, AppColors.dark.textPrimary);
        expect(textTheme.bodySmall?.color, AppColors.dark.textSecondary);
      });

      test('SnackBar 主題設定正確', () {
        final theme = AppTheme.dark;
        expect(
          theme.snackBarTheme.backgroundColor,
          AppColors.dark.surfaceSecondary,
        );
      });

      test('Dialog 主題設定正確', () {
        final theme = AppTheme.dark;
        expect(theme.dialogTheme.backgroundColor, AppColors.dark.surface);
      });

      test('Divider 主題設定正確', () {
        final theme = AppTheme.dark;
        expect(theme.dividerTheme.color, AppColors.dark.divider);
      });
    });

    group('淺色與深色主題差異', () {
      test('背景色不同', () {
        final light = AppTheme.light;
        final dark = AppTheme.dark;

        expect(
          light.scaffoldBackgroundColor,
          isNot(equals(dark.scaffoldBackgroundColor)),
        );
      });

      test('Brightness 不同', () {
        final light = AppTheme.light;
        final dark = AppTheme.dark;

        expect(light.brightness, Brightness.light);
        expect(dark.brightness, Brightness.dark);
      });

      test('文字顏色對比', () {
        // 淺色主題文字較深
        expect(
          AppColors.textPrimary.computeLuminance(),
          lessThan(0.2),
        );

        // 深色主題文字較淺
        expect(
          AppColors.dark.textPrimary.computeLuminance(),
          greaterThan(0.7),
        );
      });
    });

    group('狀態列樣式', () {
      test('lightStatusBar 設定正確', () {
        expect(AppTheme.lightStatusBar.statusBarIconBrightness, Brightness.light);
      });

      test('darkStatusBar 設定正確', () {
        expect(AppTheme.darkStatusBar.statusBarIconBrightness, Brightness.dark);
      });
    });
  });
}
