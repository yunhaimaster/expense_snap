import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/repositories/backup_repository.dart' show BackupInfo;
import '../../../l10n/app_localizations.dart';
import '../../providers/backup_provider.dart';
import '../../providers/google_auth_provider.dart';

/// 雲端備份區塊 — Google 帳號連接、備份/還原
class BackupSection extends StatelessWidget {
  const BackupSection({
    super.key,
    required this.authProvider,
    required this.backupProvider,
    required this.onPerformBackup,
    required this.onShowRestoreDialog,
  });

  final GoogleAuthProvider authProvider;
  final BackupProvider backupProvider;
  final VoidCallback onPerformBackup;
  final VoidCallback onShowRestoreDialog;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GoogleAccountTile(
          authProvider: authProvider,
          isOperationInProgress: backupProvider.isOperationInProgress,
        ),
        if (authProvider.isGoogleConnected) ...[
          // 備份狀態
          if (authProvider.backupStatus.lastBackupAt != null)
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(S.of(context).settings_lastBackupTime),
              subtitle: Text(
                '${authProvider.backupStatus.formattedLastBackupAt} · ${authProvider.backupStatus.formattedSize}',
              ),
            ),

          // 備份按鈕
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(S.of(context).settings_backupNow),
            subtitle: Text(S.of(context).settings_backupNowDesc),
            trailing: const Icon(Icons.chevron_right),
            enabled: !backupProvider.isOperationInProgress,
            onTap: onPerformBackup,
          ),

          // 還原按鈕
          ListTile(
            leading: const Icon(Icons.restore_outlined),
            title: Text(S.of(context).settings_restoreBackupTitle),
            subtitle: Text(S.of(context).settings_restoreBackupDesc),
            trailing: const Icon(Icons.chevron_right),
            enabled: !backupProvider.isOperationInProgress,
            onTap: onShowRestoreDialog,
          ),
        ],
      ],
    );
  }
}

/// Google 帳號 Tile
class _GoogleAccountTile extends StatelessWidget {
  const _GoogleAccountTile({
    required this.authProvider,
    required this.isOperationInProgress,
  });

  final GoogleAuthProvider authProvider;
  final bool isOperationInProgress;

  @override
  Widget build(BuildContext context) {
    if (authProvider.isGoogleConnected) {
      return ListTile(
        leading: const Icon(Icons.cloud_done, color: AppColors.success),
        title: Text(S.of(context).settings_googleDrive),
        subtitle: Text(
          authProvider.backupStatus.googleEmail ??
              S.of(context).settings_connected,
        ),
        trailing: TextButton(
          onPressed: isOperationInProgress
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
        onPressed: isOperationInProgress ? null : () => _connectGoogle(context),
        child: Text(S.of(context).settings_connect),
      ),
    );
  }

  Future<void> _connectGoogle(BuildContext context) async {
    final result = await authProvider.connectGoogle();

    if (!context.mounted) return;

    result.fold(
      onFailure: (error) {
        if (error.code != 'CANCELLED') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                S.of(context).settings_connectFailed(error.message),
              ),
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

    final result = await authProvider.disconnectGoogle();

    if (!context.mounted) return;

    result.fold(
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context).settings_disconnectFailed(error.message),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).settings_googleDisconnected),
          ),
        );
      },
    );
  }
}

/// 操作進度覆蓋層
class OperationProgressOverlay extends StatelessWidget {
  const OperationProgressOverlay({
    super.key,
    required this.backupProvider,
  });

  final BackupProvider backupProvider;

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
                  value: backupProvider.operationProgress > 0
                      ? backupProvider.operationProgress
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  backupProvider.operationMessage,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                if (backupProvider.operationProgress > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${(backupProvider.operationProgress * 100).toInt()}%',
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
class RestoreBackupDialog extends StatelessWidget {
  const RestoreBackupDialog({super.key, required this.backups});

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
