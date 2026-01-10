import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/core/utils/string_utils.dart';

void main() {
  group('StringUtils', () {
    group('levenshteinDistance', () {
      test('相同字串距離為 0', () {
        expect(StringUtils.levenshteinDistance('hello', 'hello'), 0);
        expect(StringUtils.levenshteinDistance('', ''), 0);
        expect(StringUtils.levenshteinDistance('午餐', '午餐'), 0);
      });

      test('空字串與非空字串的距離等於非空字串長度', () {
        expect(StringUtils.levenshteinDistance('', 'hello'), 5);
        expect(StringUtils.levenshteinDistance('hello', ''), 5);
        expect(StringUtils.levenshteinDistance('', '午餐'), 2);
      });

      test('單字元差異距離為 1', () {
        expect(StringUtils.levenshteinDistance('cat', 'hat'), 1); // 替換
        expect(StringUtils.levenshteinDistance('cat', 'cats'), 1); // 插入
        expect(StringUtils.levenshteinDistance('cats', 'cat'), 1); // 刪除
      });

      test('多字元差異計算正確', () {
        expect(StringUtils.levenshteinDistance('kitten', 'sitting'), 3);
        expect(StringUtils.levenshteinDistance('saturday', 'sunday'), 3);
        expect(StringUtils.levenshteinDistance('flaw', 'lawn'), 2);
      });

      test('中文字串計算正確', () {
        expect(StringUtils.levenshteinDistance('午餐', '早餐'), 1); // 替換一字
        expect(StringUtils.levenshteinDistance('交通費', '交通'), 1); // 刪除一字
        expect(StringUtils.levenshteinDistance('午餐費用', '午餐費'), 1); // 刪除一字
      });

      test('完全不同字串距離等於較長字串長度', () {
        expect(StringUtils.levenshteinDistance('abc', 'xyz'), 3);
        expect(StringUtils.levenshteinDistance('ab', 'xyz'), 3);
      });

      test('交換順序結果相同', () {
        expect(
          StringUtils.levenshteinDistance('hello', 'hallo'),
          StringUtils.levenshteinDistance('hallo', 'hello'),
        );
        expect(
          StringUtils.levenshteinDistance('午餐', '晚餐'),
          StringUtils.levenshteinDistance('晚餐', '午餐'),
        );
      });
    });

    group('similarityRatio', () {
      test('相同字串相似度為 1.0', () {
        expect(StringUtils.similarityRatio('hello', 'hello'), 1.0);
        expect(StringUtils.similarityRatio('午餐', '午餐'), 1.0);
      });

      test('空字串與空字串相似度為 1.0', () {
        expect(StringUtils.similarityRatio('', ''), 1.0);
      });

      test('空字串與非空字串相似度為 0.0', () {
        expect(StringUtils.similarityRatio('', 'hello'), 0.0);
        expect(StringUtils.similarityRatio('hello', ''), 0.0);
      });

      test('部分相似字串相似度介於 0 和 1 之間', () {
        // "hello" vs "hallo" = 距離 1，長度 5，相似度 = 1 - 1/5 = 0.8
        expect(StringUtils.similarityRatio('hello', 'hallo'), closeTo(0.8, 0.01));

        // "午餐" vs "晚餐" = 距離 1，長度 2，相似度 = 1 - 1/2 = 0.5
        expect(StringUtils.similarityRatio('午餐', '晚餐'), closeTo(0.5, 0.01));
      });

      test('完全不同字串相似度為 0.0', () {
        expect(StringUtils.similarityRatio('abc', 'xyz'), 0.0);
      });

      test('相似度適用於常見支出描述', () {
        // 相似描述
        expect(
          StringUtils.similarityRatio('午餐費用', '午餐費'),
          greaterThanOrEqualTo(0.6),
        );
        expect(
          StringUtils.similarityRatio('計程車', '計程車費'),
          greaterThanOrEqualTo(0.6),
        );

        // 不相似描述
        expect(
          StringUtils.similarityRatio('午餐', '交通'),
          lessThan(0.5),
        );
      });
    });

    group('normalize', () {
      test('去除首尾空白', () {
        expect(StringUtils.normalize('  hello  '), 'hello');
        expect(StringUtils.normalize('  午餐  '), '午餐');
      });

      test('轉換為小寫', () {
        expect(StringUtils.normalize('HELLO'), 'hello');
        expect(StringUtils.normalize('Hello World'), 'hello world');
      });

      test('組合處理', () {
        expect(StringUtils.normalize('  HELLO World  '), 'hello world');
      });

      test('空字串返回空字串', () {
        expect(StringUtils.normalize(''), '');
        expect(StringUtils.normalize('   '), '');
      });
    });
  });
}
