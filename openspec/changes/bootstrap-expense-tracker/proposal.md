# Change: Bootstrap Expense Tracker MVP

## Why
企業員工需要即時記錄報銷支出，目前流程繁瑣：拍照、手動記錄金額、月底整理 Excel、人手轉換匯率。
此 App 讓員工拍照即記錄，自動處理匯率轉換，一鍵匯出報銷單 + 收據。

## What Changes
This is a greenfield project - all capabilities are new.

### Core Features
- **Expense Management**: CRUD 支出記錄，軟刪除機制，月份分頁瀏覽
- **Receipt Capture**: 拍照/相簿選取，自動壓縮儲存，生成縮圖
- **Currency Conversion**: HKD/CNY/USD 自動匯率，24h 快取，離線/預設 fallback
- **Data Export**: 月份 Excel 報銷單 + 收據 ZIP，一鍵分享
- **Cloud Backup**: Google Drive 備份/還原（可選功能）
- **Offline Support**: 網絡狀態偵測，離線模式提示

### Spec Review - Refinements Made
原始 spec 已相當完整，以下為審查後的微調：

1. **Security Enhancement**
   - 明確 EXIF metadata 處理（保留或移除）
   - Token refresh 流程說明

2. **Edge Case Handling**
   - 同毫秒圖片命名衝突 → 加入 UUID suffix
   - API 重試邏輯 → Dio 內建 retry interceptor

3. **Scope Deferred (Future)**
   - 搜尋/篩選功能
   - 支出分類標籤
   - 生物辨識鎖定
   - PDF 匯出
   - 多設備同步衝突處理

## Impact

### Affected Specs (New)
- `expense-management` - 核心支出 CRUD
- `receipt-capture` - 收據圖片處理
- `currency-conversion` - 匯率轉換
- `data-export` - 匯出功能
- `cloud-backup` - 雲端備份
- `offline-support` - 離線支援

### Affected Code
- `lib/` - 全新 Flutter 專案結構
- Database schema: `expenses`, `exchange_rate_cache`, `backup_status`, `app_settings`

### Dependencies
- 無現有代碼依賴（新專案）
- 外部 API: fawazahmed0/currency-api, Google Drive API

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Exchange rate API 不穩定 | 雙 API fallback + 24h cache + 預設匯率 |
| 圖片佔用空間過大 | 壓縮至 75% quality, 1920x1080 max |
| Google OAuth 複雜度 | 使用官方 google_sign_in package |
| 離線資料遺失 | SQLite 本地持久化 + 雲端備份提示 |

## Decisions Made

### 原始決定
1. **EXIF Metadata**: ✅ 移除圖片 GPS/位置資訊以保護隱私
2. **Expense Categories**: ✅ MVP 不包含，延後至 v2
3. **Multiple Devices**: ✅ MVP 僅支援覆蓋還原，不處理衝突合併

### 🆕 審查後新增決定

4. **Data Model Fixes**:
   - 新增 `deleted_at` 欄位用於 30 天清理計算
   - 移除未使用的 `needs_sync` 欄位
   - 金額以「分」儲存（INTEGER）避免浮點誤差
   - 匯率以 ×10⁶ 精度儲存

5. **Architecture Enhancements**:
   - 新增 `domain/` 層包含 use cases
   - 依賴注入移至 Phase 1（而非 Phase 6）
   - 定義 sealed class 錯誤類型

6. **Navigation**: ✅ 使用 Bottom Navigation Bar（首頁 | 匯出 | 設定）

7. **Onboarding**: ✅ 首次啟動要求輸入使用者名稱

8. **Deleted Items View**: ✅ 設定頁面新增「已刪除項目」入口

9. **Input Validation**:
   - 金額: 0.01 ~ 9,999,999.99
   - 描述: 1-500 字元
   - 日期: 不可晚於今日

10. **Security**:
    - 圖片路徑驗證（防止目錄遍歷攻擊）
    - Google OAuth 使用最小權限 `drive.file` scope

11. **Performance**:
    - SQLite 啟用 WAL mode
    - 縮圖快取（50MB 限制）
    - 匯率 API 30 秒冷卻

12. **Background Jobs**: ✅ 使用 workmanager 執行每週清理

### 明確排除範圍（Non-Goals）

| 功能 | 狀態 | 說明 |
|------|------|------|
| 備份加密 | ❌ 排除 | 接受未加密 ZIP 風險 |
| 重複偵測 | ❌ 排除 | 不警告相似支出 |
| Excel 匯入 | ❌ 排除 | 不支援從其他來源匯入 |
| 圖片裁剪/旋轉 | ❌ 排除 | 僅支援原圖 |
| 深色模式 | ❌ 排除 | MVP 僅淺色主題 |
| 多語言 | ❌ 排除 | 僅繁體中文 |
| Accessibility | ⚠️ 基礎 | 僅基本觸控目標，無完整無障礙支援 |
