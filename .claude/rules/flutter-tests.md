---
paths: test/**/*.dart
---

# Test File Rules

## Test Structure

```dart
void main() {
  // 設置 mock 和共用 fixtures
  late MockRepository mockRepo;

  setUp(() {
    mockRepo = MockRepository();
  });

  group('ClassName', () {
    group('methodName', () {
      test('應該處理正常情況', () {
        // Arrange
        // Act
        // Assert
      });

      test('應該處理錯誤情況', () {
        // ...
      });
    });
  });
}
```

## Widget Tests

```dart
testWidgets('應該顯示正確的 UI', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MultiProvider(
        providers: [...],
        child: MyWidget(),
      ),
    ),
  );

  // 單一 frame
  await tester.pump();

  // 等待動畫完成
  await tester.pumpAndSettle();

  expect(find.byType(MyWidget), findsOneWidget);
  expect(find.text('Expected Text'), findsOneWidget);
});
```

## Mocking

```dart
// 使用 Mockito
@GenerateMocks([ExpenseRepository, ExchangeRateService])
void main() {}

// 設置 mock 行為
when(mockRepo.getExpenses()).thenAnswer((_) async => Result.success([]));

// 驗證呼叫
verify(mockRepo.getExpenses()).called(1);
```

## Finder 常用方法

- `find.byType(Widget)` - 按類型
- `find.byKey(Key('id'))` - 按 Key
- `find.text('text')` - 按文字
- `find.byIcon(Icons.add)` - 按圖標
- `find.descendant(of: parent, matching: child)` - 後代

## Matcher 常用方法

- `findsOneWidget` - 找到一個
- `findsNothing` - 找不到
- `findsNWidgets(n)` - 找到 n 個
- `findsAtLeastNWidgets(n)` - 至少 n 個

## 金額測試注意

金額以「分」儲存，測試時：
```dart
// 正確
expect(expense.amountCents, equals(1050)); // $10.50

// 錯誤 - 不要用 double
expect(expense.amount, equals(10.50)); // 浮點誤差
```
