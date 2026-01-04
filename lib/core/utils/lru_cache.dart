import 'dart:collection';

/// LRU 快取實作
///
/// 使用 LinkedHashMap 實現最近最少使用（Least Recently Used）快取策略。
/// 當快取達到容量上限時，自動移除最久未使用的項目。
///
/// 注意事項：
/// - 此實作非執行緒安全，僅適用於單一 Isolate 環境
/// - 若儲存 null 值，get() 將無法區分「鍵不存在」與「值為 null」
///   （建議使用非空值類型 V，或先用 containsKey 檢查）
class LruCache<K, V> {
  LruCache({required this.maxSize}) : assert(maxSize > 0);

  /// 快取容量上限
  final int maxSize;

  /// 底層儲存（使用 accessOrder 模式的 LinkedHashMap）
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  /// 取得快取項目，並將其移至最近使用位置
  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      // 移除後重新插入，使其成為最近使用
      _cache[key] = value;
    }
    return value;
  }

  /// 儲存快取項目
  void put(K key, V value) {
    // 若已存在，先移除（以更新順序）
    _cache.remove(key);

    // 若已達上限，移除最舊項目
    if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = value;
  }

  /// 檢查是否包含指定鍵
  bool containsKey(K key) => _cache.containsKey(key);

  /// 移除指定項目
  V? remove(K key) => _cache.remove(key);

  /// 清空快取
  void clear() => _cache.clear();

  /// 目前快取數量
  int get length => _cache.length;

  /// 快取是否為空
  bool get isEmpty => _cache.isEmpty;

  /// 快取是否已滿
  bool get isFull => _cache.length >= maxSize;
}
