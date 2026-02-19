import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/currency_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';

/// 外觀區塊 — 主題、語言、幣種
class AppearanceSection extends StatelessWidget {
  const AppearanceSection({
    super.key,
    required this.onShowThemeDialog,
    required this.onShowLanguageDialog,
    required this.onShowCurrencyDialog,
  });

  final VoidCallback onShowThemeDialog;
  final VoidCallback onShowLanguageDialog;
  final VoidCallback onShowCurrencyDialog;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    return Column(
      children: [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(S.of(context).settings_theme),
                  subtitle: Text(
                    _getThemeModeLabel(context, themeProvider.themeMode),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onShowThemeDialog,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.animation_outlined),
                  title: Text(S.of(context).settings_reduceMotion),
                  subtitle: Text(
                    S.of(context).settings_reduceMotionDesc,
                  ),
                  value: themeProvider.reduceMotion,
                  onChanged: (value) => themeProvider.setReduceMotion(value),
                ),
              ],
            );
          },
        ),
        // 語言設定
        Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) {
            return ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(S.of(context).settings_language),
              subtitle: Text(localeProvider.currentLocaleName),
              trailing: const Icon(Icons.chevron_right),
              onTap: onShowLanguageDialog,
            );
          },
        ),
        // 主要幣種設定
        ListTile(
          leading: const Icon(Icons.currency_exchange_outlined),
          title: Text(S.of(context).settings_primaryCurrency),
          subtitle: Text(
            '${CurrencyConstants.currencySymbols[provider.primaryCurrency]} '
            '${provider.primaryCurrency}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onShowCurrencyDialog,
        ),
      ],
    );
  }

  String _getThemeModeLabel(BuildContext context, AppThemeMode mode) {
    final s = S.of(context);
    switch (mode) {
      case AppThemeMode.light:
        return s.settings_themeLight;
      case AppThemeMode.dark:
        return s.settings_themeDark;
      case AppThemeMode.system:
        return s.settings_themeSystem;
    }
  }
}
