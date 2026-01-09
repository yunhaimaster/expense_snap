---
paths: lib/presentation/widgets/**/*.dart, lib/presentation/screens/**/*.dart
---

# Widget Rules

## Structure

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({
    super.key,
    required this.title,
    this.onTap,
  });

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return // ...
  }
}
```

## Performance Patterns

### const Constructors
```dart
// ✅ 正確
const SizedBox(height: 16),
const Icon(Icons.add),
const EdgeInsets.all(16),

// ❌ 錯誤 - 每次 build 都創建新實例
SizedBox(height: 16),
Icon(Icons.add),
```

### ListView
```dart
// ✅ 長列表用 builder
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemTile(items[index]),
)

// ❌ 短列表才用 children
ListView(
  children: items.map((i) => ItemTile(i)).toList(),
)
```

### RepaintBoundary
```dart
// 動畫或頻繁更新的區域
RepaintBoundary(
  child: AnimatedWidget(...),
)
```

## Size Limits

- **Widget < 250 lines** - 超過就拆分
- **build() < 100 lines** - 提取 _buildXxx 方法
- **嵌套 < 5 層** - 提取子 widget

## 拆分示例

```dart
// ❌ 過長的 build
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      // 50 行 header...
      // 80 行 body...
      // 40 行 footer...
    ],
  );
}

// ✅ 拆分後
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      _buildHeader(),
      _buildBody(),
      _buildFooter(),
    ],
  );
}

Widget _buildHeader() {
  // ...
}
```

## Provider 使用

```dart
// ✅ 讀取用 Selector
Selector<ExpenseProvider, int>(
  selector: (_, p) => p.totalCents,
  builder: (_, total, __) => Text(formatCurrency(total)),
)

// ✅ 事件用 read
ElevatedButton(
  onPressed: () => context.read<ExpenseProvider>().refresh(),
  child: const Text('Refresh'),
)

// ❌ 避免 watch 在回調中
onPressed: () => context.watch<ExpenseProvider>().refresh(), // 錯誤！
```

## Accessibility

```dart
Semantics(
  label: '刪除支出',
  button: true,
  child: IconButton(
    icon: const Icon(Icons.delete),
    onPressed: onDelete,
  ),
)
```

## i18n

```dart
// ✅ 使用 S.of(context)
Text(S.of(context).expenseTitle)

// ❌ 硬編碼
Text('支出標題')
```

## 常用 Widget 位置

| Widget | 路徑 |
|--------|------|
| EmptyState | `lib/presentation/widgets/common/empty_state.dart` |
| Skeleton | `lib/presentation/widgets/common/skeleton.dart` |
| DebouncedButton | `lib/presentation/widgets/common/debounced_button.dart` |
