# Design: Receipt OCR

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Add Expense Screen                    │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │ ImagePicker │───▶│  OcrService │───▶│ Form Fields │  │
│  └─────────────┘    └─────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                      OcrService                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │              ML Kit Text Recognition             │    │
│  └─────────────────────────────────────────────────┘    │
│                            │                             │
│                            ▼                             │
│  ┌─────────────────────────────────────────────────┐    │
│  │              ReceiptParser                       │    │
│  │  • extractCurrency()                            │    │
│  │  • extractAmount()                              │    │
│  │  • extractDescription()                         │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

## Components

### 1. OcrService (`lib/services/ocr_service.dart`)

負責調用 ML Kit 進行文字識別。

```dart
class OcrService {
  final TextRecognizer _textRecognizer;

  /// 從圖片路徑執行 OCR
  Future<Result<RecognizedText>> recognizeText(String imagePath);

  /// 釋放資源
  Future<void> dispose();
}
```

**設計決策**：
- 使用 `TextRecognizer` with Chinese + Latin script
- 服務註冊到 ServiceLocator，生命週期跟隨 app
- 返回 `Result<T>` 保持錯誤處理一致性

### 2. ReceiptParser (`lib/services/receipt_parser.dart`)

負責解析 OCR 文字，提取結構化資料。

```dart
class ReceiptParseResult {
  final String? currency;      // 識別到的幣別代碼 (HKD/CNY/USD)
  final int? amountCents;      // 金額（分）
  final String? description;   // 店名/描述
  final double confidence;     // 信心分數 0-1
}

class ReceiptParser {
  final String defaultCurrency;

  /// 解析 OCR 結果
  ReceiptParseResult parse(RecognizedText text);
}
```

### 3. Currency Detection Strategy

```dart
// 優先級：明確代碼 > 符號 + 上下文 > 用戶預設
class CurrencyDetector {
  // 幣別模式
  static const patterns = {
    'HKD': [r'HKD', r'港幣', r'港元'],
    'CNY': [r'CNY', r'RMB', r'人民幣', r'元'],
    'USD': [r'USD', r'美元', r'美金'],
  };

  // 符號映射（需結合上下文）
  static const symbols = {
    r'\$': ['HKD', 'USD'],  // 需要其他信號判斷
    r'¥|￥': ['CNY'],
  };
}
```

**Fallback 邏輯**：
1. 搜尋明確幣別代碼/文字
2. 搜尋幣別符號
3. 使用用戶設定的預設幣別

### 4. Amount Extraction Strategy

```dart
class AmountExtractor {
  /// Hybrid 策略：關鍵字優先 + 位置判斷
  int? extract(RecognizedText text) {
    // 1. 找關鍵字旁的金額
    final keywordAmount = _findAmountNearKeyword(text, [
      '總計', 'Total', '合計', '應付', '實付', 'Amount',
    ]);
    if (keywordAmount != null) return keywordAmount;

    // 2. Fallback: 底部區域最大金額
    return _findLargestAmountInBottomHalf(text);
  }
}
```

**金額解析**：
- 支援 `123.45`, `123,456.78`, `$123.45` 格式
- 轉換為「分」儲存：`(dollars * 100).round()`
- 過濾電話號碼（>8位連續數字）

### 5. Description Extraction Strategy

```dart
class DescriptionExtractor {
  /// 提取店名作為描述
  String? extract(RecognizedText text) {
    // 1. 找收據頂部文字（通常是店名）
    // 2. 過濾地址、電話、日期等
    // 3. 識別「店」「餐廳」「公司」「商店」等關鍵字
    // 4. 限制長度，保持簡潔
  }
}
```

## Integration with Add Expense Screen

```dart
// add_expense_screen.dart 修改
class _AddExpenseScreenState extends State<AddExpenseScreen> {
  Future<void> _onImageCaptured(String imagePath) async {
    setState(() => _isProcessingOcr = true);

    final ocrService = sl<OcrService>();
    final result = await ocrService.recognizeText(imagePath);

    result.fold(
      onSuccess: (text) {
        final parser = ReceiptParser(
          defaultCurrency: settings.defaultCurrency,
        );
        final parsed = parser.parse(text);

        // 自動填入表單
        if (parsed.currency != null) {
          _currencyController.value = parsed.currency;
        }
        if (parsed.amountCents != null) {
          _amountController.text = _formatAmount(parsed.amountCents);
        }
        if (parsed.description != null) {
          _descriptionController.text = parsed.description;
        }
      },
      onFailure: (error) {
        // 靜默失敗，用戶可手動輸入
        debugPrint('OCR failed: $error');
      },
    );

    setState(() => _isProcessingOcr = false);
  }
}
```

## UI Changes

### Loading State
拍照後顯示 shimmer/spinner 在表單欄位上，表示正在識別。

### Confidence Indicator (Optional)
可選：在自動填入的欄位旁顯示小圖示，提示「AI 識別」，讓用戶知道需要確認。

## Testing Strategy

### Unit Tests
- `ReceiptParser` 各種收據格式測試
- `CurrencyDetector` 幣別識別測試
- `AmountExtractor` 金額提取測試

### Integration Tests
- 模擬 OCR 結果 → 驗證表單填入
- 錯誤處理 → 驗證 graceful degradation

### Sample Test Cases
```dart
// 測試案例
'總計: $123.45' → amountCents: 12345
'Total HKD 100.00' → currency: 'HKD', amountCents: 10000
'XX餐廳\n地址...\n總計 ¥88' → description: 'XX餐廳', currency: 'CNY'
```

## Performance Considerations

- ML Kit 首次載入約 200-500ms，後續 < 100ms
- 大圖片先壓縮再 OCR（使用現有 ImageService）
- 在 isolate 中執行避免 UI 卡頓

## Error Handling

| Scenario | Handling |
|----------|----------|
| OCR 完全失敗 | 靜默失敗，用戶手動輸入 |
| 無法識別金額 | 金額欄位留空 |
| 無法識別幣別 | 使用預設幣別 |
| 處理超時 (>5s) | 取消 OCR，提示用戶 |

## Future Enhancements (Out of Scope)
- 學習用戶修正，提升準確度
- 支援更多幣別
- 商品明細逐項識別
- 雲端 OCR fallback（需網路）
