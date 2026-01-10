/// 字串處理工具類
///
/// 提供字串比較、相似度計算等功能
class StringUtils {
  StringUtils._();

  /// 計算兩個字串的 Levenshtein 編輯距離
  ///
  /// 編輯距離是將一個字串轉換為另一個字串所需的最少操作次數
  /// 操作包括：插入、刪除、替換
  ///
  /// 使用 Wagner-Fischer 動態規劃演算法，空間複雜度 O(min(m,n))
  static int levenshteinDistance(String s1, String s2) {
    // 空字串邊界情況
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    // 確保 shorter 是較短的字串（優化空間）
    final shorter = s1.length <= s2.length ? s1 : s2;
    final longer = s1.length <= s2.length ? s2 : s1;

    final m = shorter.length;
    final n = longer.length;

    // 只需要兩行：當前行和前一行
    var previousRow = List<int>.generate(m + 1, (i) => i);
    var currentRow = List<int>.filled(m + 1, 0);

    for (var j = 1; j <= n; j++) {
      currentRow[0] = j;

      for (var i = 1; i <= m; i++) {
        final cost = shorter[i - 1] == longer[j - 1] ? 0 : 1;

        currentRow[i] = _min3(
          currentRow[i - 1] + 1, // 插入
          previousRow[i] + 1, // 刪除
          previousRow[i - 1] + cost, // 替換
        );
      }

      // 交換行
      final temp = previousRow;
      previousRow = currentRow;
      currentRow = temp;
    }

    return previousRow[m];
  }

  /// 計算兩個字串的相似度比例 (0.0 - 1.0)
  ///
  /// 基於 Levenshtein 距離，1.0 表示完全相同，0.0 表示完全不同
  static double similarityRatio(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;

    return 1.0 - (distance / maxLength);
  }

  /// 正規化字串（去空白、轉小寫）
  static String normalize(String input) {
    return input.trim().toLowerCase();
  }

  /// 三個數取最小值
  static int _min3(int a, int b, int c) {
    var min = a;
    if (b < min) min = b;
    if (c < min) min = c;
    return min;
  }
}
