import 'package:expense_snap/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/presentation/widgets/forms/date_picker_field.dart';

void main() {
  group('DatePickerField', () {
    testWidgets('renders quick date buttons by default', (tester) async {
      DateTime selectedDate = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: DatePickerField(
              value: selectedDate,
              onChanged: (date) => selectedDate = date,
            ),
          ),
        ),
      );

      // 應有「今天」和「昨天」按鈕
      expect(find.text('今天'), findsOneWidget);
      expect(find.text('昨天'), findsOneWidget);
    });

    testWidgets('hides quick buttons when showQuickButtons is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: DatePickerField(
              value: DateTime.now(),
              onChanged: (_) {},
              showQuickButtons: false,
            ),
          ),
        ),
      );

      // 不應有快捷按鈕
      expect(find.text('今天'), findsNothing);
      expect(find.text('昨天'), findsNothing);
    });

    testWidgets('today button selects today', (tester) async {
      DateTime selectedDate = DateTime.now().subtract(const Duration(days: 5));
      final today = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DatePickerField(
                  value: selectedDate,
                  onChanged: (date) {
                    setState(() => selectedDate = date);
                  },
                );
              },
            ),
          ),
        ),
      );

      // 點擊「今天」
      await tester.tap(find.text('今天'));
      await tester.pump();

      // 應選中今天
      expect(selectedDate.year, today.year);
      expect(selectedDate.month, today.month);
      expect(selectedDate.day, today.day);
    });

    testWidgets('yesterday button selects yesterday', (tester) async {
      DateTime selectedDate = DateTime.now();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DatePickerField(
                  value: selectedDate,
                  onChanged: (date) {
                    setState(() => selectedDate = date);
                  },
                );
              },
            ),
          ),
        ),
      );

      // 點擊「昨天」
      await tester.tap(find.text('昨天'));
      await tester.pump();

      // 應選中昨天
      expect(selectedDate.year, yesterday.year);
      expect(selectedDate.month, yesterday.month);
      expect(selectedDate.day, yesterday.day);
    });

    testWidgets('today chip is highlighted when today is selected',
        (tester) async {
      final today = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: DatePickerField(
              value: today,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // 找到「今天」ActionChip
      final todayChip = find.widgetWithText(ActionChip, '今天');
      expect(todayChip, findsOneWidget);

      // 檢查 Chip 樣式（通過 ActionChip 的屬性）
      final chip = tester.widget<ActionChip>(todayChip);
      expect(chip.labelStyle?.fontWeight, FontWeight.bold);
    });

    testWidgets('disabled state prevents interactions', (tester) async {
      DateTime selectedDate = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: DatePickerField(
              value: selectedDate,
              onChanged: (date) => selectedDate = date,
              enabled: false,
            ),
          ),
        ),
      );

      // 點擊「昨天」不應改變日期
      final initialDate = selectedDate;
      await tester.tap(find.text('昨天'));
      await tester.pump();

      expect(selectedDate, initialDate);
    });
  });

  group('MonthPickerField', () {
    testWidgets('displays year and month', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: MonthPickerField(
              year: 2026,
              month: 1,
              onChanged: (year, month) {},
            ),
          ),
        ),
      );

      expect(find.text('2026 年 1 月'), findsOneWidget);
    });

    testWidgets('opens month picker dialog on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Scaffold(
            body: MonthPickerField(
              year: 2026,
              month: 1,
              onChanged: (year, month) {},
            ),
          ),
        ),
      );

      // 點擊月份選擇器
      await tester.tap(find.byType(MonthPickerField));
      await tester.pumpAndSettle();

      // 應顯示對話框
      expect(find.text('選擇月份'), findsOneWidget);
      expect(find.text('2026 年'), findsOneWidget);
    });
  });
}
