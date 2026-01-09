---
paths: lib/presentation/providers/**/*.dart
---

# Provider Rules

## State Management Pattern

```dart
class MyProvider extends ChangeNotifier {
  // 私有狀態
  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;

  // 公開 getters
  List<Item> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 業務方法
  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getItems();
    result.fold(
      onSuccess: (data) => _items = data,
      onFailure: (e) => _error = e.message,
    );

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // 清理資源
    super.dispose();
  }
}
```

## Widget 中使用

```dart
// ✅ 正確 - 使用 Selector 減少 rebuild
Selector<ExpenseProvider, int>(
  selector: (_, p) => p.totalAmountCents,
  builder: (_, total, __) => Text(formatCurrency(total)),
)

// ✅ 正確 - 事件處理用 read
onPressed: () => context.read<ExpenseProvider>().deleteExpense(id),

// ❌ 錯誤 - Consumer 會在任何變化時 rebuild
Consumer<ExpenseProvider>(
  builder: (_, provider, __) => Text(provider.totalAmountCents.toString()),
)

// ❌ 錯誤 - watch 在事件處理中
onPressed: () => context.watch<ExpenseProvider>().deleteExpense(id),
```

## notifyListeners 注意事項

- 只在狀態真正改變時呼叫
- 批量更新時只呼叫一次
- 避免在 build 中呼叫

```dart
// ✅ 正確 - 批量更新
void updateMultiple(String name, int amount) {
  _name = name;
  _amount = amount;
  notifyListeners(); // 只呼叫一次
}

// ❌ 錯誤 - 多次通知
void updateMultiple(String name, int amount) {
  _name = name;
  notifyListeners();
  _amount = amount;
  notifyListeners();
}
```

## 金額處理

```dart
// 金額以「分」儲存
int _amountCents = 0;

// 設置時轉換
void setAmount(double dollars) {
  _amountCents = (dollars * 100).round();
  notifyListeners();
}

// 顯示時轉換
String get formattedAmount => (_amountCents / 100).toStringAsFixed(2);
```
