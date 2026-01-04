import 'package:flutter_test/flutter_test.dart';
import 'package:expense_snap/core/utils/lru_cache.dart';

void main() {
  group('LruCache', () {
    test('應正確儲存和取得項目', () {
      final cache = LruCache<String, int>(maxSize: 3);
      cache.put('a', 1);
      cache.put('b', 2);

      expect(cache.get('a'), 1);
      expect(cache.get('b'), 2);
      expect(cache.get('c'), isNull);
    });

    test('達到容量上限時應移除最舊項目', () {
      final cache = LruCache<String, int>(maxSize: 2);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3); // 應移除 'a'

      expect(cache.get('a'), isNull);
      expect(cache.get('b'), 2);
      expect(cache.get('c'), 3);
    });

    test('取得項目後應更新存取順序', () {
      final cache = LruCache<String, int>(maxSize: 2);
      cache.put('a', 1);
      cache.put('b', 2);

      // 存取 'a'，使其成為最近使用
      cache.get('a');

      // 新增 'c'，應移除 'b'（最久未使用）
      cache.put('c', 3);

      expect(cache.get('a'), 1);
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), 3);
    });

    test('更新現有項目應保持容量', () {
      final cache = LruCache<String, int>(maxSize: 2);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('a', 10); // 更新 'a'

      expect(cache.length, 2);
      expect(cache.get('a'), 10);
      expect(cache.get('b'), 2);
    });

    test('containsKey 應正確檢查', () {
      final cache = LruCache<String, int>(maxSize: 2);
      cache.put('a', 1);

      expect(cache.containsKey('a'), isTrue);
      expect(cache.containsKey('b'), isFalse);
    });

    test('remove 應移除指定項目', () {
      final cache = LruCache<String, int>(maxSize: 2);
      cache.put('a', 1);
      cache.put('b', 2);

      final removed = cache.remove('a');

      expect(removed, 1);
      expect(cache.containsKey('a'), isFalse);
      expect(cache.length, 1);
    });

    test('clear 應清空快取', () {
      final cache = LruCache<String, int>(maxSize: 2);
      cache.put('a', 1);
      cache.put('b', 2);

      cache.clear();

      expect(cache.isEmpty, isTrue);
      expect(cache.length, 0);
    });

    test('isFull 應正確判斷', () {
      final cache = LruCache<String, int>(maxSize: 2);

      expect(cache.isFull, isFalse);

      cache.put('a', 1);
      expect(cache.isFull, isFalse);

      cache.put('b', 2);
      expect(cache.isFull, isTrue);
    });
  });
}
