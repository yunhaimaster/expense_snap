import 'package:expense_snap/core/constants/expense_category.dart';
import 'package:expense_snap/services/category_suggester.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CategorySuggester suggester;

  setUp(() {
    suggester = CategorySuggester();
  });

  group('CategorySuggester', () {
    group('suggestFromText', () {
      test('空字串應返回 null', () {
        expect(suggester.suggestFromText(''), isNull);
      });

      test('null 應返回 null', () {
        expect(suggester.suggestFromText(null), isNull);
      });

      test('無匹配應返回 null', () {
        expect(suggester.suggestFromText('xyz abc 123'), isNull);
        expect(suggester.suggestFromText('隨機文字'), isNull);
      });

      group('餐飲 (meals)', () {
        test('中文關鍵字', () {
          expect(suggester.suggestFromText('大家樂午餐'), ExpenseCategory.meals);
          expect(suggester.suggestFromText('星巴克咖啡'), ExpenseCategory.meals);
          expect(suggester.suggestFromText('美心餐廳'), ExpenseCategory.meals);
          expect(suggester.suggestFromText('晚餐'), ExpenseCategory.meals);
        });

        test('英文關鍵字（大小寫不敏感）', () {
          expect(suggester.suggestFromText('McDonald\'s'), ExpenseCategory.meals);
          expect(suggester.suggestFromText('STARBUCKS'), ExpenseCategory.meals);
          expect(suggester.suggestFromText('cafe'), ExpenseCategory.meals);
          expect(suggester.suggestFromText('Restaurant'), ExpenseCategory.meals);
        });
      });

      group('交通 (transport)', () {
        test('中文關鍵字', () {
          expect(suggester.suggestFromText('的士車費'), ExpenseCategory.transport);
          expect(suggester.suggestFromText('港鐵'), ExpenseCategory.transport);
          expect(suggester.suggestFromText('停車費'), ExpenseCategory.transport);
          expect(suggester.suggestFromText('機場快線'), ExpenseCategory.transport);
        });

        test('英文關鍵字', () {
          expect(suggester.suggestFromText('Uber ride'), ExpenseCategory.transport);
          expect(suggester.suggestFromText('Taxi'), ExpenseCategory.transport);
          expect(suggester.suggestFromText('parking fee'), ExpenseCategory.transport);
        });
      });

      group('住宿 (accommodation)', () {
        test('中文關鍵字', () {
          expect(suggester.suggestFromText('香港酒店'), ExpenseCategory.accommodation);
          expect(suggester.suggestFromText('住宿費'), ExpenseCategory.accommodation);
          expect(suggester.suggestFromText('旅館'), ExpenseCategory.accommodation);
        });

        test('英文關鍵字', () {
          expect(suggester.suggestFromText('Hotel booking'), ExpenseCategory.accommodation);
          expect(suggester.suggestFromText('Airbnb'), ExpenseCategory.accommodation);
        });
      });

      group('辦公用品 (officeSupplies)', () {
        test('中文關鍵字', () {
          expect(suggester.suggestFromText('辦公文具'), ExpenseCategory.officeSupplies);
          expect(suggester.suggestFromText('打印費'), ExpenseCategory.officeSupplies);
          expect(suggester.suggestFromText('影印'), ExpenseCategory.officeSupplies);
        });

        test('英文關鍵字', () {
          expect(suggester.suggestFromText('Office supplies'), ExpenseCategory.officeSupplies);
          expect(suggester.suggestFromText('Stationery'), ExpenseCategory.officeSupplies);
        });
      });

      group('通訊 (communication)', () {
        test('中文關鍵字', () {
          expect(suggester.suggestFromText('電話費'), ExpenseCategory.communication);
          expect(suggester.suggestFromText('上網費'), ExpenseCategory.communication);
          expect(suggester.suggestFromText('數據套餐'), ExpenseCategory.communication);
        });

        test('英文關鍵字', () {
          expect(suggester.suggestFromText('Mobile plan'), ExpenseCategory.communication);
          expect(suggester.suggestFromText('Internet'), ExpenseCategory.communication);
        });
      });

      group('娛樂 (entertainment)', () {
        test('中文關鍵字', () {
          expect(suggester.suggestFromText('電影票'), ExpenseCategory.entertainment);
          expect(suggester.suggestFromText('演唱會門票'), ExpenseCategory.entertainment);
          expect(suggester.suggestFromText('遊戲'), ExpenseCategory.entertainment);
        });

        test('英文關鍵字', () {
          expect(suggester.suggestFromText('Movie ticket'), ExpenseCategory.entertainment);
          expect(suggester.suggestFromText('Cinema'), ExpenseCategory.entertainment);
          expect(suggester.suggestFromText('Netflix'), ExpenseCategory.entertainment);
        });
      });

      group('醫療 (medical)', () {
        test('中文關鍵字', () {
          expect(suggester.suggestFromText('醫院掛號'), ExpenseCategory.medical);
          expect(suggester.suggestFromText('診所看診'), ExpenseCategory.medical);
          expect(suggester.suggestFromText('藥房'), ExpenseCategory.medical);
        });

        test('英文關鍵字', () {
          expect(suggester.suggestFromText('Doctor visit'), ExpenseCategory.medical);
          expect(suggester.suggestFromText('Pharmacy'), ExpenseCategory.medical);
        });
      });

      group('優先級測試', () {
        test('長關鍵字優先於短關鍵字', () {
          // 「餐廳」是長關鍵字，應優先匹配
          expect(suggester.suggestFromText('餐廳晚餐'), ExpenseCategory.meals);
        });

        test('大小寫不敏感', () {
          expect(suggester.suggestFromText('CAFE'), ExpenseCategory.meals);
          expect(suggester.suggestFromText('Hotel'), ExpenseCategory.accommodation);
          expect(suggester.suggestFromText('uBer'), ExpenseCategory.transport);
        });

        test('部分匹配', () {
          expect(suggester.suggestFromText('去大家樂吃飯'), ExpenseCategory.meals);
          expect(suggester.suggestFromText('搭港鐵返工'), ExpenseCategory.transport);
        });
      });

      group('短關鍵字', () {
        test('茶 匹配餐飲', () {
          expect(suggester.suggestFromText('奶茶'), ExpenseCategory.meals);
        });

        test('sim 匹配通訊', () {
          expect(suggester.suggestFromText('SIM卡'), ExpenseCategory.communication);
        });

        test('藥 匹配醫療', () {
          expect(suggester.suggestFromText('買藥'), ExpenseCategory.medical);
        });
      });
    });
  });
}
