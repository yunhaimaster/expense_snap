import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// 隱私權政策畫面
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.settings_privacyPolicy),
      ),
      body: Semantics(
        label: s.settings_privacyPolicy,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            s.legal_privacyContent,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
