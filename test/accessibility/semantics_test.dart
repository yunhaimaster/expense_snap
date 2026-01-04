import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/core/constants/currency_constants.dart';
import 'package:expense_snap/data/models/expense.dart';
import 'package:expense_snap/presentation/screens/home/widgets/expense_card.dart';
import 'package:expense_snap/presentation/screens/home/widgets/month_summary.dart';

void main() {
  group('無障礙 Semantics 測試', () {
    group('ExpenseCard Semantics', () {
      testWidgets('ExpenseCard 有 Semantics 包裝', (tester) async {
        final expense = Expense(
          id: 1,
          description: '午餐',
          originalAmountCents: 10000,
          originalCurrency: 'HKD',
          hkdAmountCents: 10000,
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          date: DateTime(2024, 1, 15),
          receiptImagePath: null,
          thumbnailPath: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExpenseCard(
                expense: expense,
                onTap: () {},
              ),
            ),
          ),
        );

        // 驗證 ExpenseCard 被 Semantics 包裝
        expect(find.byType(Semantics), findsWidgets);

        // 找到外層的 Semantics 元件
        final semanticsWidget = tester.widget<Semantics>(
          find.ancestor(
            of: find.byType(Card),
            matching: find.byType(Semantics),
          ).first,
        );

        // 驗證語意標籤存在且不為空
        expect(semanticsWidget.properties.label, isNotNull);
        expect(semanticsWidget.properties.label, isNotEmpty);

        // 驗證是按鈕語意
        expect(semanticsWidget.properties.button, isTrue);
      });

      testWidgets('ExcludeSemantics 用於裝飾性內容', (tester) async {
        final expense = Expense(
          id: 1,
          description: '午餐',
          originalAmountCents: 10000,
          originalCurrency: 'HKD',
          hkdAmountCents: 10000,
          exchangeRate: 1000000,
          exchangeRateSource: ExchangeRateSource.auto,
          date: DateTime(2024, 1, 15),
          receiptImagePath: null,
          thumbnailPath: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExpenseCard(
                expense: expense,
                onTap: () {},
              ),
            ),
          ),
        );

        // 驗證內部使用 ExcludeSemantics（可能有多個裝飾性元素）
        expect(find.byType(ExcludeSemantics), findsWidgets);
      });
    });

    group('MonthSummaryCard Semantics', () {
      testWidgets('MonthSummaryCard 有 Semantics 包裝', (tester) async {
        const summary = MonthSummary(
          year: 2024,
          month: 1,
          totalHkdAmountCents: 150000,
          totalCount: 15,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MonthSummaryCard(
                summary: summary,
                onPreviousMonth: () {},
                onNextMonth: () {},
                canGoNext: true,
              ),
            ),
          ),
        );

        // 驗證有 Semantics
        expect(find.byType(Semantics), findsWidgets);
      });

      testWidgets('導航按鈕有 tooltip', (tester) async {
        const summary = MonthSummary(
          year: 2024,
          month: 1,
          totalHkdAmountCents: 100000,
          totalCount: 10,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MonthSummaryCard(
                summary: summary,
                onPreviousMonth: () {},
                onNextMonth: () {},
                canGoNext: false,
              ),
            ),
          ),
        );

        // 驗證 IconButton 有 tooltip
        final iconButtons = tester.widgetList<IconButton>(
          find.descendant(
            of: find.byType(MonthSummaryCard),
            matching: find.byType(IconButton),
          ),
        );

        expect(iconButtons.length, 2);

        // 上個月按鈕
        expect(iconButtons.first.tooltip, '上個月');

        // 下個月按鈕
        expect(iconButtons.last.tooltip, '下個月');
      });

      testWidgets('統計區域使用 ExcludeSemantics', (tester) async {
        const summary = MonthSummary(
          year: 2024,
          month: 1,
          totalHkdAmountCents: 100000,
          totalCount: 10,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MonthSummaryCard(
                summary: summary,
                onPreviousMonth: () {},
                onNextMonth: () {},
                canGoNext: true,
              ),
            ),
          ),
        );

        // 驗證使用 ExcludeSemantics 排除裝飾性內容
        expect(find.byType(ExcludeSemantics), findsWidgets);
      });
    });
  });
}
