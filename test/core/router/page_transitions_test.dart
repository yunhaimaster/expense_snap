import 'package:expense_snap/core/router/page_transitions.dart';
import 'package:expense_snap/core/utils/animation_utils.dart';
import 'package:expense_snap/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SlidePageRoute', () {
    testWidgets('建立成功並顯示頁面', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  SlidePageRoute(
                    page: const Scaffold(
                      body: Center(child: Text('Slide Page')),
                    ),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Slide Page'), findsOneWidget);
    });

    testWidgets('使用正確的動畫時長', (tester) async {
      final route = SlidePageRoute(
        page: const Scaffold(),
      );

      expect(route.transitionDuration, AnimationUtils.pageTransition);
    });

    testWidgets('自訂動畫時長', (tester) async {
      const customDuration = Duration(milliseconds: 500);
      final route = SlidePageRoute(
        page: const Scaffold(),
        duration: customDuration,
      );

      expect(route.transitionDuration, customDuration);
    });

    testWidgets('fullscreenDialog 設定正確', (tester) async {
      final dialogRoute = SlidePageRoute(
        page: const Scaffold(),
        fullscreenDialog: true,
      );

      expect(dialogRoute.fullscreenDialog, isTrue);
    });
  });

  group('FadePageRoute', () {
    testWidgets('建立成功並顯示頁面', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  FadePageRoute(
                    page: const Scaffold(
                      body: Center(child: Text('Fade Page')),
                    ),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Fade Page'), findsOneWidget);
    });

    testWidgets('使用正確的動畫時長', (tester) async {
      final route = FadePageRoute(
        page: const Scaffold(),
      );

      expect(route.transitionDuration, AnimationUtils.standard);
    });
  });

  group('BottomSlidePageRoute', () {
    testWidgets('建立成功並顯示頁面', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  BottomSlidePageRoute(
                    page: const Scaffold(
                      body: Center(child: Text('Bottom Slide Page')),
                    ),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Bottom Slide Page'), findsOneWidget);
    });

    testWidgets('預設為 fullscreenDialog', (tester) async {
      final route = BottomSlidePageRoute(
        page: const Scaffold(),
      );

      expect(route.fullscreenDialog, isTrue);
    });
  });

  group('ScalePageRoute', () {
    testWidgets('建立成功並顯示頁面', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  ScalePageRoute(
                    page: const Scaffold(
                      body: Center(child: Text('Scale Page')),
                    ),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Scale Page'), findsOneWidget);
    });

    testWidgets('自訂對齊方式', (tester) async {
      final route = ScalePageRoute(
        page: const Scaffold(),
        alignment: Alignment.bottomRight,
      );

      expect(route.alignment, Alignment.bottomRight);
    });
  });

  group('頁面返回', () {
    testWidgets('SlidePageRoute 可正常返回', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  SlidePageRoute(
                    page: Scaffold(
                      appBar: AppBar(title: const Text('Detail')),
                      body: const Center(child: Text('Slide Page')),
                    ),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      // 前往新頁面
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();
      expect(find.text('Slide Page'), findsOneWidget);

      // 返回
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Navigate'), findsOneWidget);
    });

    testWidgets('BottomSlidePageRoute 可正常返回', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  BottomSlidePageRoute(
                    page: Scaffold(
                      appBar: AppBar(title: const Text('Modal')),
                      body: const Center(child: Text('Bottom Slide Page')),
                    ),
                  ),
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
        ),
      );

      // 開啟模態
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();
      expect(find.text('Bottom Slide Page'), findsOneWidget);

      // 關閉（fullscreenDialog 使用 CloseButton）
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(find.text('Open Modal'), findsOneWidget);
    });
  });
}
