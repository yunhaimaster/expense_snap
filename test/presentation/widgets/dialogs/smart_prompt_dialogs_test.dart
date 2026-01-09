import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/core/constants/currency_constants.dart';
import 'package:expense_snap/data/models/expense.dart';
import 'package:expense_snap/l10n/app_localizations.dart';
import 'package:expense_snap/presentation/widgets/dialogs/smart_prompt_dialogs.dart';

void main() {
  group('SmartPromptDialogs', () {
    group('showDuplicateWarning', () {
      testWidgets('displays existing expense details', (tester) async {
        final expense = Expense(
          id: 1,
          date: DateTime(2026, 1, 4),
          originalAmountCents: 10000,
          originalCurrency: 'HKD',
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          hkdAmountCents: 10000,
          description: '午餐',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await SmartPromptDialogs.showDuplicateWarning(
                      context,
                      existingExpense: expense,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        );

        // 顯示對話框
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 驗證對話框內容
        expect(find.text('可能重複'), findsOneWidget);
        expect(find.text('發現相似的支出記錄：'), findsOneWidget);
        expect(find.text('午餐'), findsOneWidget);
        expect(find.text('確定要繼續新增嗎？'), findsOneWidget);

        // 驗證按鈕
        expect(find.text('取消'), findsOneWidget);
        expect(find.text('繼續新增'), findsOneWidget);
      });

      testWidgets('returns false when cancelled', (tester) async {
        final expense = Expense(
          id: 1,
          date: DateTime.now(),
          originalAmountCents: 10000,
          originalCurrency: 'HKD',
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          hkdAmountCents: 10000,
          description: '午餐',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await SmartPromptDialogs.showDuplicateWarning(
                      context,
                      existingExpense: expense,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 點擊取消
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();

        expect(result, isFalse);
      });

      testWidgets('returns true when confirmed', (tester) async {
        final expense = Expense(
          id: 1,
          date: DateTime.now(),
          originalAmountCents: 10000,
          originalCurrency: 'HKD',
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          hkdAmountCents: 10000,
          description: '午餐',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await SmartPromptDialogs.showDuplicateWarning(
                      context,
                      existingExpense: expense,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 點擊繼續新增
        await tester.tap(find.text('繼續新增'));
        await tester.pumpAndSettle();

        expect(result, isTrue);
      });
    });

    group('showLargeAmountConfirmation', () {
      testWidgets('displays amount details', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await SmartPromptDialogs.showLargeAmountConfirmation(
                      context,
                      amount: 1500.0,
                      currency: 'HKD',
                      hkdAmount: 1500.0,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 驗證對話框內容
        expect(find.text('大金額確認'), findsOneWidget);
        expect(find.text('您即將記錄一筆大金額支出：'), findsOneWidget);
        expect(find.text('請確認金額是否正確？'), findsOneWidget);

        // 驗證按鈕
        expect(find.text('返回修改'), findsOneWidget);
        expect(find.text('確認正確'), findsOneWidget);
      });

      testWidgets('shows HKD equivalent for non-HKD currencies',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await SmartPromptDialogs.showLargeAmountConfirmation(
                      context,
                      amount: 200.0,
                      currency: 'USD',
                      hkdAmount: 1560.0,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 應顯示 HKD 換算金額
        expect(find.textContaining('≈ HKD'), findsOneWidget);
      });

      testWidgets('returns false when cancelled', (tester) async {
        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result =
                        await SmartPromptDialogs.showLargeAmountConfirmation(
                      context,
                      amount: 1500.0,
                      currency: 'HKD',
                      hkdAmount: 1500.0,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('返回修改'));
        await tester.pumpAndSettle();

        expect(result, isFalse);
      });

      testWidgets('returns true when confirmed', (tester) async {
        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result =
                        await SmartPromptDialogs.showLargeAmountConfirmation(
                      context,
                      amount: 1500.0,
                      currency: 'HKD',
                      hkdAmount: 1500.0,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('確認正確'));
        await tester.pumpAndSettle();

        expect(result, isTrue);
      });
    });

    group('showMonthEndReminder', () {
      testWidgets('displays expense count', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await SmartPromptDialogs.showMonthEndReminder(
                      context,
                      expenseCount: 15,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('月底提醒'), findsOneWidget);
        expect(find.text('本月即將結束！'), findsOneWidget);
        expect(find.text('您本月共有 15 筆支出記錄'), findsOneWidget);
        expect(find.text('稍後'), findsOneWidget);
        expect(find.text('去匯出'), findsOneWidget);
      });
    });
  });
}
