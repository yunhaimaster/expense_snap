import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/repositories/backup_repository.dart' show BackupInfo;
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
        title: const Text('設定'),
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
                  const _SectionHeader(title: '個人資料'),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('姓名'),
                    subtitle: Text(provider.userName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editUserName(provider),
                  ),

                  const Divider(),

                  // 外觀區塊
                  const _SectionHeader(title: '外觀'),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.palette_outlined),
                            title: const Text('主題'),
                            subtitle: Text(_getThemeModeLabel(themeProvider.themeMode)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showThemeModeDialog(themeProvider),
                          ),
                          SwitchListTile(
                            secondary: const Icon(Icons.animation_outlined),
                            title: const Text('減少動畫'),
                            subtitle: const Text('減少動態效果，適合動暈症患者'),
                            value: themeProvider.reduceMotion,
                            onChanged: (value) => themeProvider.setReduceMotion(value),
                          ),
                        ],
                      );
                    },
                  ),

                  const Divider(),

                  // 資料管理區塊
                  const _SectionHeader(title: '資料管理'),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('已刪除項目'),
                    subtitle: const Text('查看和還原已刪除的支出'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRouter.deletedItems);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.storage_outlined),
                    title: const Text('本地儲存使用量'),
                    subtitle: Text(provider.formattedStorageUsage),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined),
                    title: const Text('清理暫存檔'),
                    subtitle: const Text('釋放匯出和備份暫存空間'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _cleanupTempFiles(provider),
                  ),

                  const Divider(),

                  // 雲端備份區塊
                  const _SectionHeader(title: '雲端備份'),
                  _GoogleAccountTile(provider: provider),

                  if (provider.isGoogleConnected) ...[
                    // 備份狀態
                    if (provider.backupStatus.lastBackupAt != null)
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: const Text('上次備份'),
                        subtitle: Text(
                          '${provider.backupStatus.formattedLastBackupAt} · ${provider.backupStatus.formattedSize}',
                        ),
                      ),

                    // 備份按鈕
                    ListTile(
                      leading: const Icon(Icons.backup_outlined),
                      title: const Text('立即備份'),
                      subtitle: const Text('備份資料庫和收據到 Google 雲端硬碟'),
                      trailing: const Icon(Icons.chevron_right),
                      enabled: !provider.isOperationInProgress,
                      onTap: () => _performBackup(provider),
                    ),

                    // 還原按鈕
                    ListTile(
                      leading: const Icon(Icons.restore_outlined),
                      title: const Text('還原備份'),
                      subtitle: const Text('從 Google 雲端硬碟還原'),
                      trailing: const Icon(Icons.chevron_right),
                      enabled: !provider.isOperationInProgress,
                      onTap: () => _showRestoreDialog(provider),
                    ),
                  ],

                  const Divider(),

                  // 關於區塊
                  const _SectionHeader(title: '關於'),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('版本'),
                    subtitle: Text('${AppConstants.appName} v${AppConstants.appVersion}'),
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

  String _getThemeModeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return '淺色';
      case AppThemeMode.dark:
        return '深色';
      case AppThemeMode.system:
        return '跟隨系統';
    }
  }

  Future<void> _showThemeModeDialog(ThemeProvider themeProvider) async {
    final selectedMode = await showDialog<AppThemeMode>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('選擇主題'),
        children: [
          _ThemeModeOption(
            icon: Icons.light_mode_outlined,
            title: '淺色',
            value: AppThemeMode.light,
            groupValue: themeProvider.themeMode,
            onTap: () => Navigator.of(dialogContext).pop(AppThemeMode.light),
          ),
          _ThemeModeOption(
            icon: Icons.dark_mode_outlined,
            title: '深色',
            value: AppThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onTap: () => Navigator.of(dialogContext).pop(AppThemeMode.dark),
          ),
          _ThemeModeOption(
            icon: Icons.settings_brightness_outlined,
            title: '跟隨系統',
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
          title: const Text('編輯姓名'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '姓名',
              hintText: '用於報銷單標題',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('儲存'),
            ),
          ],
        ),
      );

      if (newName == null || newName.isEmpty || !mounted) return;

      final success = await provider.updateUserName(newName);

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已儲存')),
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
            content: Text('清理失敗: ${error.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (count) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已清理 $count 個暫存檔案')),
        );
      },
    );
  }

  Future<void> _performBackup(SettingsProvider provider) async {
    // 確認對話框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('備份到雲端'),
        content: const Text('這將備份所有支出記錄和收據圖片到 Google 雲端硬碟。\n\n繼續？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('備份'),
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
            content: Text('備份失敗: ${error.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('備份成功'),
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
        const SnackBar(content: Text('沒有找到雲端備份')),
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
        title: const Text('確認還原'),
        content: Text(
          '這將使用 "${selectedBackup.fileName}" 取代目前所有資料。\n\n'
          '此操作無法復原，確定要繼續嗎？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('還原'),
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
            content: Text('還原失敗: ${error.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('還原成功'),
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
        title: const Text('Google 雲端硬碟'),
        subtitle: Text(provider.backupStatus.googleEmail ?? '已連接'),
        trailing: TextButton(
          onPressed: provider.isOperationInProgress
              ? null
              : () => _disconnectGoogle(context),
          child: const Text('斷開'),
        ),
      );
    }

    return ListTile(
      leading: const Icon(Icons.cloud_outlined),
      title: const Text('Google 雲端硬碟'),
      subtitle: const Text('尚未連接'),
      trailing: ElevatedButton(
        onPressed: provider.isOperationInProgress
            ? null
            : () => _connectGoogle(context),
        child: const Text('連接'),
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
              content: Text('連接失敗: ${error.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已連接 Google 帳號'),
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
        title: const Text('斷開 Google 帳號'),
        content: const Text('斷開後將無法使用雲端備份功能。\n\n確定要斷開嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('斷開'),
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
            content: Text('斷開失敗: ${error.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已斷開 Google 帳號')),
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
      title: const Text('選擇備份'),
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
          child: const Text('取消'),
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
