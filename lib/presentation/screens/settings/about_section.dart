import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';

/// 關於區塊 — 版本、隱私政策、服務條款
class AboutSection extends StatelessWidget {
  const AboutSection({super.key, this.packageInfo});

  final PackageInfo? packageInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(S.of(context).settings_version),
          subtitle: Text(
            packageInfo != null
                ? '${packageInfo!.appName} v${packageInfo!.version} (${packageInfo!.buildNumber})'
                : '${AppConstants.appName} v...',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(S.of(context).settings_privacyPolicy),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).pushNamed(
            AppRouter.privacyPolicy,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(S.of(context).settings_termsOfService),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).pushNamed(
            AppRouter.termsOfService,
          ),
        ),
      ],
    );
  }
}
