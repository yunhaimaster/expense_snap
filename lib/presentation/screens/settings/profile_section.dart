import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';

/// 個人資料區塊 — 使用者名稱編輯
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.provider,
    required this.onEditName,
  });

  final SettingsProvider provider;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.person_outline),
      title: Text(S.of(context).settings_nameLabel),
      subtitle: Text(provider.userName),
      trailing: const Icon(Icons.chevron_right),
      onTap: onEditName,
    );
  }
}
