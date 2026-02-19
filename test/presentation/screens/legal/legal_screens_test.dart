import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_snap/l10n/app_localizations.dart';
import 'package:expense_snap/presentation/screens/legal/privacy_policy_screen.dart';
import 'package:expense_snap/presentation/screens/legal/terms_of_service_screen.dart';

void main() {
  group('PrivacyPolicyScreen', () {
    testWidgets('應正確渲染不拋異常', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: PrivacyPolicyScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('應顯示 AppBar 標題', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: PrivacyPolicyScreen(),
        ),
      );
      await tester.pump();

      // 「隱私權政策」標題
      expect(find.text('隱私權政策'), findsAtLeastNWidgets(1));
    });

    testWidgets('應使用 SingleChildScrollView', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: PrivacyPolicyScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('應使用 SelectableText 顯示內容', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: PrivacyPolicyScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('應有 Semantics 標籤', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: PrivacyPolicyScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(Semantics), findsAtLeastNWidgets(1));
    });
  });

  group('TermsOfServiceScreen', () {
    testWidgets('應正確渲染不拋異常', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: TermsOfServiceScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('應顯示 AppBar 標題', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: TermsOfServiceScreen(),
        ),
      );
      await tester.pump();

      // 「服務條款」標題
      expect(find.text('服務條款'), findsAtLeastNWidgets(1));
    });

    testWidgets('應使用 SingleChildScrollView', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: TermsOfServiceScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('應使用 SelectableText 顯示內容', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: TermsOfServiceScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('應有 Semantics 標籤', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: TermsOfServiceScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(Semantics), findsAtLeastNWidgets(1));
    });
  });
}
