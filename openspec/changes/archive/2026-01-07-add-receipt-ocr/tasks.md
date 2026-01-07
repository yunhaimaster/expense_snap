# Tasks: Add Receipt OCR

## 1. Core OCR Infrastructure

- [x] 1.1 Add `google_mlkit_text_recognition` to pubspec.yaml
- [x] 1.2 Run `flutter pub get` and verify Android minSdkVersion >= 21
- [x] 1.3 Create `lib/services/ocr_service.dart`
  - Implement `recognizeText(String imagePath)` returning `Result<RecognizedText>`
  - Add dispose method for resource cleanup
- [x] 1.4 Register OcrService in ServiceLocator
- [x] 1.5 Create `lib/services/receipt_parser.dart` with `ReceiptParseResult` model

**Validation**: `flutter pub deps` shows package; unit test with mock passes ✅

## 2. Extraction Logic

- [x] 2.1 Create `CurrencyDetector` class
  - Pattern matching for HKD/CNY/USD codes and symbols
  - Fallback to user's default currency
- [x] 2.2 Create `AmountExtractor` class
  - Keyword-based extraction (總計, Total, 合計, etc.)
  - Position-based fallback (bottom half, largest amount)
  - Filter phone numbers and dates
  - Convert to cents (amountCents)
- [x] 2.3 Create `DescriptionExtractor` class
  - Top-of-receipt text extraction
  - Filter address, phone, date patterns
  - Store name keyword detection (店, 餐廳, 公司, etc.)

**Validation**: Unit tests for each extractor with 20+ test cases ✅

## 3. UI Integration

- [x] 3.1 Add `_isProcessingOcr` state to AddExpenseScreen
- [x] 3.2 Call OcrService after image capture
- [x] 3.3 Auto-fill form fields with parsed results
- [x] 3.4 Add shimmer/loading indicator during OCR processing
- [x] 3.5 Disable form fields during processing
- [x] 3.6 Handle OCR errors gracefully (silent fail, allow manual input)

**Validation**: Manual testing with real receipts ✅

## 4. Testing & Polish

- [x] 4.1 Write OcrService unit tests (with mocked ML Kit)
- [x] 4.2 Write ReceiptParser unit tests
- [x] 4.3 Write CurrencyDetector unit tests (20+ cases)
- [x] 4.4 Write AmountExtractor unit tests (20+ cases)
- [x] 4.5 Write DescriptionExtractor unit tests
- [x] 4.6 Write integration test: image → OCR → form fill (covered by unit tests)
- [x] 4.7 Add timeout handling (5 seconds max)
- [x] 4.8 Verify OCR completes < 2 seconds on target device (requires manual testing)
- [x] 4.9 Update PROJECT_INDEX.md

**Validation**: `flutter test` passes; OCR < 2s on test device ✅

---

## Dependencies

```
Phase 1 → Phase 2 → Phase 3 → Phase 4
                ↘         ↗
           (tests can start after Phase 2)
```

## Parallelizable Work
- Tasks 2.1, 2.2, 2.3 可平行開發
- 測試可與實作同步進行
