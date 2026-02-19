import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/currency_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/repositories/backup_repository.dart' show BackupInfo;
import '../../../l10n/app_localizations.dart';
import '../../providers/backup_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/google_auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/skeleton.dart';
import 'about_section.dart';
import 'appearance_section.dart';
import 'backup_section.dart';
import 'profile_section.dart';
import 'storage_section.dart';

/// 設定畫面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    // 載入版本資訊
    unawaited(
      PackageInfo.fromPlatform().then((info) {
        if (mounted) setState(() => _packageInfo = info);
      }),
    );
    // 載入設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<SettingsProvider>().loadSettings());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settings_title),
      ),
      body: Consumer3<SettingsProvider, GoogleAuthProvider, BackupProvider>(
        builder: (context, settings, auth, backup, child) {
          // 載入中 - 使用 shimmer 骨架屏
          if (settings.isLoading) {
            return const SettingsListSkeleton(itemCount: 6);
          }

          return Stack(
            children: [
              ListView(
                children: [
                  // 個人資料區塊
                  _SectionHeader(title: S.of(context).settings_profile),
                  ProfileSection(
                    provider: settings,
                    onEditName: () => _editUserName(settings),
                  ),

                  const Divider(),

                  // 外觀區塊
                  _SectionHeader(title: S.of(context).settings_appearance),
                  AppearanceSection(
                    primaryCurrency: settings.primaryCurrency,
                    onShowThemeDialog: () => _showThemeModeDialog(
                      context.read<ThemeProvider>(),
                    ),
                    onShowLanguageDialog: () => _showLanguageDialog(
                      context.read<LocaleProvider>(),
                    ),
                    onShowCurrencyDialog: () => _showCurrencyDialog(settings),
                  ),

                  const Divider(),

                  // 資料管理區塊
                  _SectionHeader(title: S.of(context).settings_data),
                  StorageSection(
                    backupProvider: backup,
                    onCleanupTempFiles: () => _cleanupTempFiles(backup),
                  ),

                  const Divider(),

                  // 雲端備份區塊
                  _SectionHeader(title: S.of(context).settings_cloudBackup),
                  BackupSection(
                    authProvider: auth,
                    backupProvider: backup,
                    onPerformBackup: () => _performBackup(backup),
                    onShowRestoreDialog: () => _showRestoreDialog(auth, backup),
                  ),

                  const Divider(),

                  // 關於區塊
                  _SectionHeader(title: S.of(context).settings_about),
                  AboutSection(packageInfo: _packageInfo),
                ],
              ),

              // 操作進度覆蓋層
              if (backup.isOperationInProgress)
                OperationProgressOverlay(backupProvider: backup),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showLanguageDialog(LocaleProvider localeProvider) async {
    final s = S.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(s.settings_language),
        children: [
          _LanguageOption(
            code: 'system',
            title: s.settings_languageSystem,
            isSelected: localeProvider.isSelected('system'),
            onTap: () {
              unawaited(localeProvider.setLocaleByCode('system'));
              Navigator.of(dialogContext).pop();
            },
          ),
          ...LocaleProvider.localeNames.entries
              .where((e) => e.key != 'system')
              .map(
                (e) => _LanguageOption(
                  code: e.key,
                  title: e.value,
                  isSelected: localeProvider.isSelected(e.key),
                  onTap: () {
                    unawaited(localeProvider.setLocaleByCode(e.key));
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _showCurrencyDialog(SettingsProvider provider) async {
    final s = S.of(context);
    final selectedCurrency = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.settings_selectCurrency),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 警告訊息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.settings_changeCurrencyWarning,
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 幣種列表
            SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: CurrencyConstants.primaryCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = CurrencyConstants.primaryCurrencies[index];
                  final isSelected = currency == provider.primaryCurrency;
                  final symbol =
                      CurrencyConstants.currencySymbols[currency] ?? currency;
                  final name =
                      CurrencyConstants.currencyNames[currency] ?? currency;
                  return ListTile(
                    leading: Text(
                      symbol,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    title: Text(currency),
                    subtitle: Text(name),
                    trailing: isSelected
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    selected: isSelected,
                    onTap: () => Navigator.of(dialogContext).pop(currency),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.common_cancel),
          ),
        ],
      ),
    );

    if (selectedCurrency == null || !mounted) return;

    final success = await provider.updatePrimaryCurrency(selectedCurrency);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).settings_saved)),
      );
    }
  }

  Future<void> _showThemeModeDialog(ThemeProvider themeProvider) async {
    final selectedMode = await showDialog<AppThemeMode>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(S.of(context).settings_selectTheme),
        children: [
          _ThemeModeOption(
            icon: Icons.light_mode_outlined,
            title: S.of(context).settings_themeLight,
            value: AppThemeMode.light,
            groupValue: themeProvider.themeMode,
            onTap: () => Navigator.of(dialogContext).pop(AppThemeMode.light),
          ),
          _ThemeModeOption(
            icon: Icons.dark_mode_outlined,
            title: S.of(context).settings_themeDark,
            value: AppThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onTap: () => Navigator.of(dialogContext).pop(AppThemeMode.dark),
          ),
          _ThemeModeOption(
            icon: Icons.settings_brightness_outlined,
            title: S.of(context).settings_languageSystem,
            value: AppThemeMode.system,
            groupValue: themeProvider.themeMode,
            onTap: () => Navigator.of(dialogContext).pop(AppThemeMode.system),
          ),
        ],
      ),
    );

    if (selectedMode != null) {
      await themeProvider.setThemeMode(selectedMode);
    }
  }

  Future<void> _editUserName(SettingsProvider provider) async {
    final controller = TextEditingController(text: provider.userName);

    try {
      final newName = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(S.of(context).settings_editName),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: S.of(context).settings_nameLabel,
              hintText: S.of(context).settings_nameHint,
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).common_cancel),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(S.of(context).common_save),
            ),
          ],
        ),
      );

      if (newName == null || newName.isEmpty || !mounted) return;

      final success = await provider.updateUserName(newName);

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).settings_saved)),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _cleanupTempFiles(BackupProvider provider) async {
    final result = await provider.cleanupTempFiles();

    if (!mounted) return;

    result.fold(
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).settings_cleanupFailed(error.message)),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (count) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).settings_cleanedFiles(count)),
          ),
        );
      },
    );
  }

  Future<void> _performBackup(BackupProvider provider) async {
    // 確認對話框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).settings_backupToCloud),
        content: Text(S.of(context).settings_backupConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.of(context).settings_backup),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await provider.backupToGoogleDrive();

    if (!mounted) return;

    // 短暫延遲讓進度動畫完成
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    provider.resetOperationState();

    result.fold(
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).settings_backupFailed(error.message)),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).settings_backupSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }

  Future<void> _showRestoreDialog(
    GoogleAuthProvider auth,
    BackupProvider backup,
  ) async {
    // 載入備份列表
    await backup.loadCloudBackups();

    if (!mounted) return;

    if (backup.cloudBackups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).settings_noBackupFound)),
      );
      return;
    }

    // 顯示備份選擇對話框
    final selectedBackup = await showDialog<BackupInfo>(
      context: context,
      builder: (context) => RestoreBackupDialog(backups: backup.cloudBackups),
    );

    if (selectedBackup == null || !mounted) return;

    // 確認還原
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).settings_confirmRestoreTitle),
        content: Text(
          S
              .of(context)
              .settings_confirmRestoreDesc(
                selectedBackup.fileName,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).common_cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.of(context).settings_restore),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await backup.restoreFromGoogleDrive(selectedBackup.fileId);

    if (!mounted) return;

    // 短暫延遲讓進度動畫完成
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    backup.resetOperationState();

    result.fold(
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context).settings_restoreFailed(error.message),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (_) {
        // 刷新支出列表
        unawaited(context.read<ExpenseProvider>().refresh());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).settings_restoreSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }
}

/// 區塊標題
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 主題模式選項
class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.icon,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final AppThemeMode value;
  final AppThemeMode groupValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      selected: isSelected,
      onTap: onTap,
    );
  }
}

/// 語言選項
class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.code,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String code;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        code == 'system'
            ? Icons.settings_brightness_outlined
            : Icons.translate_outlined,
      ),
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      selected: isSelected,
      onTap: onTap,
    );
  }
}
