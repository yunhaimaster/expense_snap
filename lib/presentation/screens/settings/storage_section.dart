import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/backup_provider.dart';

/// 資料管理區塊 — 已刪除項目、儲存量、清除快取
class StorageSection extends StatelessWidget {
  const StorageSection({
    super.key,
    required this.backupProvider,
    required this.onCleanupTempFiles,
  });

  final BackupProvider backupProvider;
  final VoidCallback onCleanupTempFiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: Text(S.of(context).settings_deletedItems),
          subtitle: Text(S.of(context).settings_deletedItemsDesc),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            unawaited(Navigator.of(context).pushNamed(AppRouter.deletedItems));
          },
        ),
        ListTile(
          leading: const Icon(Icons.storage_outlined),
          title: Text(S.of(context).settings_storageUsage),
          subtitle: Text(backupProvider.formattedStorageUsage),
        ),
        ListTile(
          leading: const Icon(Icons.cleaning_services_outlined),
          title: Text(S.of(context).settings_clearCache),
          subtitle: Text(S.of(context).settings_clearCacheDesc),
          trailing: const Icon(Icons.chevron_right),
          onTap: onCleanupTempFiles,
        ),
      ],
    );
  }
}
