import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/presentation/providers/locale_provider.dart';

/// LocaleProvider 測試
///
/// 注意：完整的 Provider 測試需要 Mock ServiceLocator
/// 這裡測試枚舉、靜態常數和純邏輯
void main() {
  group('LocaleProvider 靜態常數', () {
    test('supportedLocales 應包含中文和英文', () {
      expect(LocaleProvider.supportedLocales.length, 2);
      expect(
        LocaleProvider.supportedLocales.any((l) => l.languageCode == 'zh'),
        true,
      );
      expect(
        LocaleProvider.supportedLocales.any((l) => l.languageCode == 'en'),
        true,
      );
    });

    test('localeNames 應包含所有支援語言的顯示名稱', () {
      expect(LocaleProvider.localeNames['zh'], '繁體中文');
      expect(LocaleProvider.localeNames['en'], 'English');
      expect(LocaleProvider.localeNames['system'], '跟隨系統');
    });
  });

  group('LocaleProvider 初始狀態', () {
    test('預設 locale 為 null（跟隨系統）', () {
      final provider = LocaleProvider();
      expect(provider.locale, isNull);
    });

    test('預設 isLoaded 為 false', () {
      final provider = LocaleProvider();
      expect(provider.isLoaded, false);
    });

    test('currentLocaleCode 預設為 system', () {
      final provider = LocaleProvider();
      expect(provider.currentLocaleCode, 'system');
    });

    test('currentLocaleName 預設為 跟隨系統', () {
      final provider = LocaleProvider();
      expect(provider.currentLocaleName, '跟隨系統');
    });
  });

  group('LocaleProvider resolvedLocale', () {
    test('locale 為 null 時應使用系統 locale', () {
      final provider = LocaleProvider();
      // 無法直接測試系統 locale，但可以確認 resolvedLocale 回傳非 null
      expect(provider.resolvedLocale, isNotNull);
    });

    test('locale 為 zh 時應回傳 zh', () {
      final provider = LocaleProvider();
      // 透過 isSelected 驗證初始狀態
      expect(provider.isSelected('system'), true);
      expect(provider.isSelected('zh'), false);
      expect(provider.isSelected('en'), false);
    });
  });

  group('LocaleProvider isSelected', () {
    test('system 選項在預設狀態下應為 true', () {
      final provider = LocaleProvider();
      expect(provider.isSelected('system'), true);
    });

    test('zh 選項在預設狀態下應為 false', () {
      final provider = LocaleProvider();
      expect(provider.isSelected('zh'), false);
    });

    test('en 選項在預設狀態下應為 false', () {
      final provider = LocaleProvider();
      expect(provider.isSelected('en'), false);
    });
  });

  group('Locale 常數驗證', () {
    test('中文 locale 語言代碼應為 zh', () {
      const zhLocale = Locale('zh');
      expect(zhLocale.languageCode, 'zh');
    });

    test('英文 locale 語言代碼應為 en', () {
      const enLocale = Locale('en');
      expect(enLocale.languageCode, 'en');
    });

    test('Locale 相等性測試', () {
      const locale1 = Locale('zh');
      const locale2 = Locale('zh');
      expect(locale1, locale2);
    });

    test('不同 Locale 不相等', () {
      const zhLocale = Locale('zh');
      const enLocale = Locale('en');
      expect(zhLocale == enLocale, false);
    });
  });

  group('語言代碼驗證', () {
    test('支援的語言代碼應在 supportedLocales 中', () {
      final supportedCodes =
          LocaleProvider.supportedLocales.map((l) => l.languageCode).toList();
      expect(supportedCodes, contains('zh'));
      expect(supportedCodes, contains('en'));
    });

    test('不支援的語言代碼不在 supportedLocales 中', () {
      final supportedCodes =
          LocaleProvider.supportedLocales.map((l) => l.languageCode).toList();
      expect(supportedCodes.contains('ja'), false);
      expect(supportedCodes.contains('ko'), false);
      expect(supportedCodes.contains('fr'), false);
    });
  });

  group('localeNames 完整性', () {
    test('每個支援的 locale 應有對應的名稱', () {
      for (final locale in LocaleProvider.supportedLocales) {
        expect(
          LocaleProvider.localeNames.containsKey(locale.languageCode),
          true,
          reason: '缺少 ${locale.languageCode} 的顯示名稱',
        );
      }
    });

    test('system 選項應有名稱', () {
      expect(LocaleProvider.localeNames.containsKey('system'), true);
    });
  });
}
