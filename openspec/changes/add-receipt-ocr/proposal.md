# Change: Add Receipt OCR

## Why
目前用戶新增支出時需要手動輸入所有欄位。對於有收據的支出，這是重複勞動，容易造成金額輸入錯誤。透過 OCR 自動識別收據內容，可減少輸入時間並提升準確度。

## What Changes
- 新增 `OcrService` 使用 Google ML Kit Text Recognition 進行離線文字識別
- 新增 `ReceiptParser` 解析收據內容（幣別、金額、店名）
- 修改 Add Expense Screen，拍照後自動執行 OCR 並填入表單
- 新增 OCR 處理中的 loading 狀態顯示
- 新增 `google_mlkit_text_recognition` 依賴（App 增加約 15MB）

## Impact
- Affected specs: `receipt-ocr` (new capability)
- Affected code:
  - `lib/services/ocr_service.dart` (new)
  - `lib/services/receipt_parser.dart` (new)
  - `lib/presentation/screens/add_expense/` (modified)
  - `lib/core/di/service_locator.dart` (modified)
  - `pubspec.yaml` (modified)

---

## Additional Context

### Approach
使用 **Google ML Kit Text Recognition** 實現離線 OCR：
- 完全離線運作，符合 offline-first 架構
- 支援繁/簡體中文 + 英文
- 免費使用

### Scope

**In Scope:**
- 收據文字識別（OCR）
- 幣別偵測（符號/代碼/文字 + 用戶預設 fallback）
- 金額提取（關鍵字優先 + 位置判斷）
- 店名/描述提取
- 拍照後自動 OCR + 填入表單

**Out of Scope:**
- 雲端 OCR（保持離線優先）
- 商品明細逐項識別
- 收據分類建議
- 歷史 OCR 學習

### User Flow
1. 用戶點擊「新增支出」
2. 拍攝或選擇收據圖片
3. 自動執行 OCR（顯示 loading）
4. 識別結果填入表單（幣別、金額、描述）
5. 用戶確認/修改後儲存

### Success Criteria
- OCR 處理時間 < 2 秒
- 金額識別準確率 > 80%（標準收據）
- 離線環境可正常使用
- 不影響現有拍照流程

### Risks
| Risk | Mitigation |
|------|------------|
| 中文識別準確度 | 使用 Chinese script 模型，提供編輯功能 |
| App 體積增加 | 約 15MB，可接受 |
| 手寫收據識別差 | 清楚告知為「收據掃描」，手寫建議手動輸入 |

### Related Files
- `lib/services/image_service.dart` - 現有圖片處理服務
- `lib/presentation/screens/add_expense/` - 新增支出畫面
