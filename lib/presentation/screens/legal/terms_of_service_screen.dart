import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// 服務條款畫面
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.settings_termsOfService),
      ),
      body: Semantics(
        label: s.settings_termsOfService,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            s.legal_termsContent,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
