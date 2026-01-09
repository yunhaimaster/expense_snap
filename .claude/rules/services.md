---
paths: lib/services/**/*.dart, lib/data/**/*.dart
---

# Service & Data Layer Rules

## Result Pattern

所有可能失敗的操作使用 `Result<T>` 而非拋異常：

```dart
// ✅ 正確
Future<Result<List<Expense>>> getExpenses() async {
  try {
    final data = await _dataSource.fetchAll();
    return Result.success(data);
  } catch (e, stack) {
    return Result.failure(
      AppException.fromError(e, stackTrace: stack),
    );
  }
}

// ❌ 錯誤 - 不要拋異常
Future<List<Expense>> getExpenses() async {
  final data = await _dataSource.fetchAll();
  if (data == null) throw Exception('No data');
  return data;
}
```

## 處理 Result

```dart
final result = await repository.getExpenses();

// 方法 1: fold
result.fold(
  onSuccess: (expenses) => _expenses = expenses,
  onFailure: (error) => _error = error.message,
);

// 方法 2: Pattern matching (Dart 3)
switch (result) {
  case Success(value: final expenses):
    _expenses = expenses;
  case Failure(error: final error):
    _error = error.message;
}
```

## Repository Pattern

```dart
abstract class ExpenseRepository {
  Future<Result<List<Expense>>> getAll();
  Future<Result<Expense>> getById(String id);
  Future<Result<void>> save(Expense expense);
  Future<Result<void>> delete(String id);
}

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource _localDataSource;

  ExpenseRepositoryImpl(this._localDataSource);

  @override
  Future<Result<List<Expense>>> getAll() async {
    // 實作...
  }
}
```

## 依賴注入

使用 `get_it` 的 `sl` (service locator)：

```dart
// 註冊
sl.registerLazySingleton<ExpenseRepository>(
  () => ExpenseRepositoryImpl(sl()),
);

// 使用
final repo = sl<ExpenseRepository>();
```

## 金額與匯率

```dart
// 金額：以「分」儲存 (INTEGER)
final amountCents = (dollars * 100).round();

// 匯率：以 ×10⁶ 精度儲存 (INTEGER)
final storedRate = (rate * 1000000).round();

// 轉換計算
final convertedCents = (amountCents * storedRate) ~/ 1000000;
```

## 快取策略

```dart
class CachedService {
  final _cache = <String, CacheEntry>{};
  static const _maxAge = Duration(hours: 1);

  Future<Result<Data>> getData(String key) async {
    final cached = _cache[key];
    if (cached != null && !cached.isExpired(_maxAge)) {
      return Result.success(cached.data);
    }

    final result = await _fetchFresh(key);
    result.fold(
      onSuccess: (data) => _cache[key] = CacheEntry(data),
      onFailure: (_) {},
    );
    return result;
  }
}
```
