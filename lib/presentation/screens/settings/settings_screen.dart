import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/repositories/backup_repository.dart' show BackupInfo;
import '../../../l10n/app_localizations.dart';
import '../../providers/expense_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/skeleton.dart';

/// 設定畫面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // 載入設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<SettingsProvider>();
      // 始終載入設定（讓 provider 處理重複載入）
      provider.loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settings_title),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          // 載入中 - 使用 shimmer 骨架屏
          if (provider.isLoading) {
            return const SettingsListSkeleton(itemCount: 6);
          }

          return Stack(
            children: [
              ListView(
                children: [
                  // 個人資料區塊
                  _SectionHeader(title: S.of(context).settings_profile),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(S.of(context).settings_nameLabel),
                    subtitle: Text(provider.userName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editUserName(provider),
                  ),

                  const Divider(),

                  // 外觀區塊
                  _SectionHeader(title: S.of(context).settings_appearance),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.palette_outlined),
                            title: Text(S.of(context).settings_theme),
                            subtitle: Text(_getThemeModeLabel(context, themeProvider.themeMode)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showThemeModeDialog(themeProvider),
                          ),
                          SwitchListTile(
                            secondary: const Icon(Icons.animation_outlined),
                            title: Text(S.of(context).settings_reduceMotion),
                            subtitle: Text(S.of(context).settings_reduceMotionDesc),
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
                        onTap: () => _showLanguageDialog(localeProvider),
                      );
                    },
                  ),

                  const Divider(),

                  // 資料管理區塊
                  _SectionHeader(title: S.of(context).settings_data),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(S.of(context).settings_deletedItems),
                    subtitle: Text(S.of(context).settings_deletedItemsDesc),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRouter.deletedItems);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.storage_outlined),
                    title: Text(S.of(context).settings_storageUsage),
                    subtitle: Text(provider.formattedStorageUsage),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined),
                    title: Text(S.of(context).settings_clearCache),
                    subtitle: Text(S.of(context).settings_clearCacheDesc),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _cleanupTempFiles(provider),
                  ),

                  const Divider(),

                  // 雲端備份區塊
                  _SectionHeader(title: S.of(context).settings_cloudBackup),
                  _GoogleAccountTile(provider: provider),

                  if (provider.isGoogleConnected) ...[
                    // 備份狀態
                    if (provider.backupStatus.lastBackupAt != null)
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(S.of(context).settings_lastBackupTime),
                        subtitle: Text(
                          '${provider.backupStatus.formattedLastBackupAt} · ${provider.backupStatus.formattedSize}',
                        ),
                      ),

                    // 備份按鈕
                    ListTile(
                      leading: const Icon(Icons.backup_outlined),
                      title: Text(S.of(context).settings_backupNow),
                      subtitle: Text(S.of(context).settings_backupNowDesc),
                      trailing: const Icon(Icons.chevron_right),
                      enabled: !provider.isOperationInProgress,
                      onTap: () => _performBackup(provider),
                    ),

                    // 還原按鈕
                    ListTile(
                      leading: const Icon(Icons.restore_outlined),
                      title: Text(S.of(context).settings_restoreBackupTitle),
                      subtitle: Text(S.of(context).settings_restoreBackupDesc),
                      trailing: const Icon(Icons.chevron_right),
                      enabled: !provider.isOperationInProgress,
                      onTap: () => _showRestoreDialog(provider),
                    ),
                  ],

                  const Divider(),

                  // 關於區塊
                  _SectionHeader(title: S.of(context).settings_about),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(S.of(context).settings_version),
                    subtitle: const Text('${AppConstants.appName} v${AppConstants.appVersion}'),
                  ),
                ],
              ),

              // 操作進度覆蓋層
              if (provider.isOperationInProgress)
                _OperationProgressOverlay(provider: provider),
            ],
          );
        },
      ),
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

  Future<void> _showLanguageDialog(LocaleProvider localeProvider) async {
    final s = S.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(s.settings_language),
        children: [
          _LanguageOption(
            code: 'system',
            title: S.of(context).settings_languageSystem,
            isSelected: localeProvider.isSelected('system'),
            onTap: () {
              localeProvider.setLocaleByCode('system');
              Navigator.of(dialogContext).pop();
            },
          ),
          _LanguageOption(
            code: 'zh',
            title: '繁體中文',
            isSelected: localeProvider.isSelected('zh'),
            onTap: () {
              localeProvider.setLocaleByCode('zh');
              Navigator.of(dialogContext).pop();
            },
          ),
          _LanguageOption(
            code: 'en',
            title: 'English',
            isSelected: localeProvider.isSelected('en'),
            onTap: () {
              localeProvider.setLocaleByCode('en');
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
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
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
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

  Future<void> _cleanupTempFiles(SettingsProvider provider) async {
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
          SnackBar(content: Text(S.of(context).settings_cleanedFiles(count))),
        );
      },
    );
  }

  Future<void> _performBackup(SettingsProvider provider) async {
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

  Future<void> _showRestoreDialog(SettingsProvider provider) async {
    // 載入備份列表
    await provider.loadCloudBackups();

    if (!mounted) return;

    if (provider.cloudBackups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).settings_noBackupFound)),
      );
      return;
    }

    // 顯示備份選擇對話框
    final selectedBackup = await showDialog<BackupInfo>(
      context: context,
      builder: (context) => _RestoreBackupDialog(backups: provider.cloudBackups),
    );

    if (selectedBackup == null || !mounted) return;

    // 確認還原
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).settings_confirmRestoreTitle),
        content: Text(S.of(context).settings_confirmRestoreDesc(selectedBackup.fileName)),
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

    final result = await provider.restoreFromGoogleDrive(selectedBackup.fileId);

    if (!mounted) return;

    // 短暫延遲讓進度動畫完成
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    provider.resetOperationState();

    result.fold(
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).settings_restoreFailed(error.message)),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (_) {
        // 刷新支出列表
        context.read<ExpenseProvider>().refresh();

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

/// Google 帳號 Tile
class _GoogleAccountTile extends StatelessWidget {
  const _GoogleAccountTile({required this.provider});

  final SettingsProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isGoogleConnected) {
      return ListTile(
        leading: const Icon(Icons.cloud_done, color: AppColors.success),
        title: Text(S.of(context).settings_googleDrive),
        subtitle: Text(provider.backupStatus.googleEmail ?? S.of(context).settings_connected),
        trailing: TextButton(
          onPressed: provider.isOperationInProgress
              ? null
              : () => _disconnectGoogle(context),
          child: Text(S.of(context).settings_disconnect),
        ),
      );
    }

    return ListTile(
      leading: const Icon(Icons.cloud_outlined),
      title: Text(S.of(context).settings_googleDrive),
      subtitle: Text(S.of(context).settings_notConnected),
      trailing: ElevatedButton(
        onPressed: provider.isOperationInProgress
            ? null
            : () => _connectGoogle(context),
        child: Text(S.of(context).settings_connect),
      ),
    );
  }

  Future<void> _connectGoogle(BuildContext context) async {
    final result = await provider.connectGoogle();

    if (!context.mounted) return;

    // 短暫延遲讓狀態更新
    await Future.delayed(const Duration(milliseconds: 300));
    provider.resetOperationState();

    result.fold(
      onFailure: (error) {
        if (error.code != 'CANCELLED') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).settings_connectFailed(error.message)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).settings_googleConnected),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }

  Future<void> _disconnectGoogle(BuildContext context) async {
    // 確認對話框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).settings_disconnectTitle),
        content: Text(S.of(context).settings_disconnectConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.of(context).settings_disconnect),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await provider.disconnectGoogle();

    if (!context.mounted) return;

    provider.resetOperationState();

    result.fold(
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).settings_disconnectFailed(error.message)),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).settings_googleDisconnected)),
        );
      },
    );
  }
}

/// 操作進度覆蓋層
class _OperationProgressOverlay extends StatelessWidget {
  const _OperationProgressOverlay({required this.provider});

  final SettingsProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  value: provider.operationProgress > 0
                      ? provider.operationProgress
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  provider.operationMessage,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                if (provider.operationProgress > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${(provider.operationProgress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 還原備份對話框
class _RestoreBackupDialog extends StatelessWidget {
  const _RestoreBackupDialog({required this.backups});

  final List<BackupInfo> backups;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).settings_selectBackup),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: backups.length,
          itemBuilder: (context, index) {
            final backup = backups[index];
            return ListTile(
              leading: const Icon(Icons.backup),
              title: Text(
                Formatters.formatDateTimeForDisplay(backup.createdAt),
              ),
              subtitle: Text(_formatSize(backup.sizeBytes)),
              onTap: () => Navigator.of(context).pop(backup),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).common_cancel),
        ),
      ],
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 主題模式選項（避免 RadioListTile 棄用警告）
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
