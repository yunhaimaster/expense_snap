import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_snap/core/constants/expense_category.dart';

void main() {
  group('ExpenseCategory', () {
    test('應有 8 個預設分類', () {
      expect(ExpenseCategory.values.length, 8);
      expect(ExpenseCategory.values, contains(ExpenseCategory.meals));
      expect(ExpenseCategory.values, contains(ExpenseCategory.transport));
      expect(ExpenseCategory.values, contains(ExpenseCategory.accommodation));
      expect(ExpenseCategory.values, contains(ExpenseCategory.officeSupplies));
      expect(ExpenseCategory.values, contains(ExpenseCategory.communication));
      expect(ExpenseCategory.values, contains(ExpenseCategory.entertainment));
      expect(ExpenseCategory.values, contains(ExpenseCategory.medical));
      expect(ExpenseCategory.values, contains(ExpenseCategory.other));
    });

    test('enum name 應使用 camelCase', () {
      expect(ExpenseCategory.meals.name, 'meals');
      expect(ExpenseCategory.officeSupplies.name, 'officeSupplies');
    });
  });

  group('ExpenseCategoryExtension', () {
    group('i18nKey', () {
      test('應返回正確的 i18n key 格式', () {
        expect(ExpenseCategory.meals.i18nKey, 'category_meals');
        expect(ExpenseCategory.transport.i18nKey, 'category_transport');
        expect(
            ExpenseCategory.officeSupplies.i18nKey, 'category_officeSupplies');
        expect(ExpenseCategory.other.i18nKey, 'category_other');
      });
    });

    group('fromString', () {
      test('null 輸入應返回 null', () {
        expect(ExpenseCategoryExtension.fromString(null), isNull);
      });

      test('有效值應返回對應 enum', () {
        expect(ExpenseCategoryExtension.fromString('meals'),
            ExpenseCategory.meals);
        expect(ExpenseCategoryExtension.fromString('transport'),
            ExpenseCategory.transport);
        expect(ExpenseCategoryExtension.fromString('officeSupplies'),
            ExpenseCategory.officeSupplies);
        expect(
            ExpenseCategoryExtension.fromString('other'), ExpenseCategory.other);
      });

      test('無效值應返回 other 並記錄警告', () {
        expect(ExpenseCategoryExtension.fromString('invalid'),
            ExpenseCategory.other);
        expect(ExpenseCategoryExtension.fromString('unknown_category'),
            ExpenseCategory.other);
        expect(ExpenseCategoryExtension.fromString(''), ExpenseCategory.other);
      });

      test('所有有效分類名稱應正確解析', () {
        for (final category in ExpenseCategory.values) {
          expect(
            ExpenseCategoryExtension.fromString(category.name),
            category,
            reason: '${category.name} 應正確解析為 $category',
          );
        }
      });
    });

    group('getColor', () {
      testWidgets('淺色主題應返回正確顏色', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Builder(
              builder: (context) {
                // 驗證淺色主題顏色
                expect(
                  ExpenseCategory.meals.getColor(context),
                  const Color(0xFF4CAF50),
                );
                expect(
                  ExpenseCategory.transport.getColor(context),
                  const Color(0xFF2196F3),
                );
                expect(
                  ExpenseCategory.accommodation.getColor(context),
                  const Color(0xFF9C27B0),
                );
                expect(
                  ExpenseCategory.officeSupplies.getColor(context),
                  const Color(0xFFFF9800),
                );
                expect(
                  ExpenseCategory.communication.getColor(context),
                  const Color(0xFF00BCD4),
                );
                expect(
                  ExpenseCategory.entertainment.getColor(context),
                  const Color(0xFFF44336),
                );
                expect(
                  ExpenseCategory.medical.getColor(context),
                  const Color(0xFFE91E63),
                );
                expect(
                  ExpenseCategory.other.getColor(context),
                  const Color(0xFF607D8B),
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('深色主題應返回較亮顏色', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Builder(
              builder: (context) {
                // 驗證深色主題顏色（較亮）
                expect(
                  ExpenseCategory.meals.getColor(context),
                  const Color(0xFF81C784),
                );
                expect(
                  ExpenseCategory.transport.getColor(context),
                  const Color(0xFF64B5F6),
                );
                expect(
                  ExpenseCategory.accommodation.getColor(context),
                  const Color(0xFFBA68C8),
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });

    group('getTextColor', () {
      testWidgets('淺色主題應返回白色文字', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Builder(
              builder: (context) {
                for (final category in ExpenseCategory.values) {
                  expect(
                    category.getTextColor(context),
                    Colors.white,
                    reason: '$category 在淺色主題應使用白色文字',
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('深色主題應返回深色文字', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Builder(
              builder: (context) {
                for (final category in ExpenseCategory.values) {
                  expect(
                    category.getTextColor(context),
                    Colors.black87,
                    reason: '$category 在深色主題應使用深色文字',
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });
  });
}
