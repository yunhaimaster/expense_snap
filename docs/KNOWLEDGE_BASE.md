# Knowledge Base

## Quick Navigation

| Topic | Link |
|-------|------|
| Architecture | [#architecture](#architecture) |
| Data Flow | [#data-flow](#data-flow) |
| Currency Handling | [#currency-handling](#currency-handling) |
| Image Processing | [#image-processing](#image-processing) |
| Error Handling | [#error-handling](#error-handling) |
| Testing | [#testing](#testing) |
| Troubleshooting | [#troubleshooting](#troubleshooting) |

---

## Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│            Presentation                  │
│  (Screens, Widgets, Providers)          │
├─────────────────────────────────────────┤
│              Domain                      │
│  (Repository Interfaces, Entities)      │
├─────────────────────────────────────────┤
│               Data                       │
│  (Repositories, Models, DataSources)    │
└─────────────────────────────────────────┘
```

### Dependency Rule

- **上層可依賴下層**：Presentation → Domain → Data
- **下層不可依賴上層**
- **Domain 層為純 Dart**：不依賴 Flutter

### Key Files by Layer

| Layer | Key Files |
|-------|-----------|
| Presentation | `providers/*.dart`, `screens/*.dart` |
| Domain | `domain/repositories/*.dart` |
| Data | `data/repositories/*.dart`, `data/models/*.dart` |

---

## Data Flow

### Add Expense Flow

```
User Input
    ↓
AddExpenseScreen
    ↓
ExpenseProvider.addExpense()
    ↓
ExpenseRepository.createExpense()
    ↓
DatabaseHelper.insert()
    ↓
SQLite
```

### Currency Conversion Flow

```
User selects currency
    ↓
ExchangeRateProvider.fetchRate()
    ↓
ExchangeRateRepository.getExchangeRate()
    ↓
[Check cache] → [Cache valid?]
    ↓ No              ↓ Yes
ExchangeRateApi    Return cached
    ↓
Store in cache
    ↓
Return rate
```

### Export Flow

```
User taps Export
    ↓
ExportScreen
    ↓
ExportService.exportMonthlyReport()
    ↓
[Generate Excel] + [Copy images to temp]
    ↓
Archive into ZIP
    ↓
share_plus.shareXFiles()
```

---

## Currency Handling

### Amount Storage (Cents)

```dart
// 使用分儲存避免浮點誤差
final amountCents = (userInput * 100).round();

// 轉換回元顯示
final displayAmount = amountCents / 100;
```

### Exchange Rate Precision

```dart
// 匯率以 ×10⁶ 精度儲存
const ratePrecision = 1000000;

// 儲存
final storedRate = (apiRate * ratePrecision).round();

// 使用
final convertedCents = (originalCents * storedRate) ~/ ratePrecision;
```

### Supported Currencies

| Code | Name | Symbol |
|------|------|--------|
| HKD | Hong Kong Dollar | HK$ |
| CNY | Chinese Yuan | ¥ |
| USD | US Dollar | US$ |

### Exchange Rate Sources

```dart
enum ExchangeRateSource {
  api,      // 即時 API
  cache,    // 本地快取
  fallback, // 預設匯率
  manual,   // 手動輸入
}
```

---

## Image Processing

### Compression Specs

| Type | Max Size | Quality | Format |
|------|----------|---------|--------|
| Original | 1920×1080 | 85% | JPEG |
| Thumbnail | 200px width | 70% | JPEG |

### Storage Paths

```
[App Private Directory]
└── receipts/
    ├── {uuid}.jpg          # 原圖
    └── {uuid}_thumb.jpg    # 縮圖
```

### Cleanup Strategy

- **啟動時清理**：每 7 天執行一次
- **背景清理**：WorkManager 週期任務
- **清理目標**：
  - 軟刪除 >30 天的支出
  - 匯出臨時檔案
  - 孤立圖片檔案

---

## Error Handling

### Result Pattern

```dart
// 成功
return Result.success(expense);

// 失敗
return Result.failure(AppException(
  code: AppException.databaseError,
  message: '儲存失敗',
  originalError: e,
));
```

### 使用 fold 處理結果

```dart
final result = await repository.createExpense(expense);
result.fold(
  onFailure: (e) => showError(e.message),
  onSuccess: (expense) => navigateToDetail(expense.id),
);
```

### 常見錯誤碼

| Code | Description | 處理方式 |
|------|-------------|---------|
| NETWORK_ERROR | 網路錯誤 | 使用快取/重試 |
| DATABASE_ERROR | 資料庫錯誤 | 顯示錯誤訊息 |
| VALIDATION_ERROR | 驗證失敗 | 顯示欄位錯誤 |
| AUTH_ERROR | 認證失敗 | 重新登入 |
| IMAGE_ERROR | 圖片處理失敗 | 跳過圖片 |

---

## Testing

### Test Categories

| Category | Path | Purpose |
|----------|------|---------|
| Unit | `test/core/`, `test/data/` | 邏輯測試 |
| Widget | `test/presentation/` | UI 測試 |
| Accessibility | `test/accessibility/` | 無障礙測試 |

### Mock Generation

```bash
# 生成 mocks
dart run build_runner build --delete-conflicting-outputs
```

### 測試慣例

```dart
// 檔案命名
test/path/to/file_test.dart

// Mock 檔案
test/path/to/file_test.mocks.dart

// 測試結構
void main() {
  group('ClassName', () {
    late MockDependency mockDep;

    setUp(() {
      mockDep = MockDependency();
    });

    test('should do something', () {
      // Arrange
      when(mockDep.method()).thenReturn(value);

      // Act
      final result = sut.doSomething();

      // Assert
      expect(result, expectedValue);
    });
  });
}
```

---

## Troubleshooting

### 常見問題

#### 匯率顯示 0.0

**原因**：網路錯誤且無快取
**解決**：
1. 檢查網路連線
2. 檢查 `exchange_rate_cache` 表
3. 確認 fallback 匯率設定

#### 圖片無法顯示

**原因**：路徑不存在或權限問題
**解決**：
1. 檢查 `receiptImagePath` 是否正確
2. 確認檔案存在
3. 檢查 `PathValidator` 結果

#### Google Drive 備份失敗

**原因**：Token 過期或權限不足
**解決**：
1. 重新登入 Google
2. 檢查 OAuth scopes
3. 確認 `flutter_secure_storage` 運作正常

#### 測試失敗：找不到 Mock

**原因**：未生成 mocks
**解決**：
```bash
dart run build_runner build --delete-conflicting-outputs
```

#### App 啟動緩慢

**原因**：資料庫初始化或清理任務
**解決**：
1. 檢查 `_initializeApp()` 日誌
2. 確認 `_performStartupCleanup()` 執行時間
3. 考慮延遲非關鍵初始化

---

## Development Tips

### 新增 Provider

1. 建立 `lib/presentation/providers/xxx_provider.dart`
2. 繼承 `ChangeNotifier`
3. 在 `main.dart` 的 `MultiProvider` 中註冊
4. 撰寫測試 `test/presentation/providers/xxx_provider_test.dart`

### 新增 Screen

1. 建立 `lib/presentation/screens/xxx/xxx_screen.dart`
2. 在 `app_router.dart` 新增路由
3. 選擇適當的 `PageRoute` 類型
4. 撰寫 Widget 測試

### 新增 Repository 方法

1. 在 `domain/repositories/` 介面新增方法
2. 在 `data/repositories/` 實作
3. 回傳 `Result<T>` 型別
4. 撰寫單元測試

### 修改資料庫結構

1. 增加 `DatabaseHelper._databaseVersion`
2. 在 `_onUpgrade` 處理 migration
3. 更新 Model 的 `fromMap`/`toMap`
4. 測試升級路徑

---

## Related Documentation

- [PROJECT_INDEX.md](../PROJECT_INDEX.md) - AI 專用快速索引
- [API.md](./API.md) - API 詳細文件
- [openspec/](../openspec/) - 功能規格
