# testing-standards Specification Delta

## ADDED Requirements

### Requirement: Concurrent Operation Testing
系統 SHALL 包含並發操作測試以驗證執行緒安全。

#### Scenario: Test concurrent database writes
- **WHEN** 執行資料庫並發測試
- **THEN** 測試 10 個同時寫入操作
- **AND** 驗證所有寫入成功
- **AND** 驗證資料一致性
- **AND** 無 race condition 錯誤

#### Scenario: Test database initialization race
- **WHEN** 執行 ServiceLocator 初始化測試
- **THEN** 模擬多個同時存取資料庫請求
- **AND** 驗證僅初始化一次
- **AND** 所有請求者獲得相同實例

#### Scenario: Test read during write
- **WHEN** 執行讀寫並發測試
- **THEN** 模擬寫入期間的讀取操作
- **AND** 驗證讀取獲得一致資料
- **AND** 無髒讀或部分讀取

### Requirement: Network Resilience Testing
系統 SHALL 包含網路韌性測試以驗證離線和超時處理。

#### Scenario: Test API timeout handling
- **WHEN** 執行 API 超時測試
- **THEN** 模擬 exchange rate API 超時
- **AND** 驗證系統使用快取/預設值
- **AND** 驗證錯誤訊息友善

#### Scenario: Test partial upload failure
- **WHEN** 執行 Google Drive 上傳測試
- **THEN** 模擬上傳中途失敗
- **AND** 驗證系統正確回滾
- **AND** 驗證不留下部分上傳

#### Scenario: Test rate limit recovery
- **WHEN** 執行 API rate limit 測試
- **THEN** 模擬 API 返回 429 Too Many Requests
- **AND** 驗證系統等待後重試
- **AND** 驗證使用者收到適當提示

### Requirement: UI State Testing
系統 SHALL 包含 UI 狀態測試以驗證各種裝置情境。

#### Scenario: Test keyboard overlay
- **WHEN** 執行鍵盤測試
- **THEN** 模擬鍵盤彈出
- **AND** 驗證輸入欄位不被遮擋
- **AND** 驗證表單可滾動

#### Scenario: Test large dataset rendering
- **WHEN** 執行大量資料渲染測試
- **THEN** 模擬 1000+ 筆支出
- **AND** 驗證列表滾動流暢（60fps）
- **AND** 驗證記憶體使用合理

#### Scenario: Test error boundary recovery
- **WHEN** 執行錯誤恢復測試
- **THEN** 模擬 widget 拋出異常
- **AND** 驗證錯誤邊界捕獲異常
- **AND** 驗證 App 不崩潰

### Requirement: Edge Case Testing
系統 SHALL 包含邊界條件測試以驗證極端情境處理。

#### Scenario: Test maximum expense count
- **WHEN** 執行最大筆數測試
- **THEN** 測試單月 10,000 筆支出
- **AND** 驗證列表正確顯示
- **AND** 驗證匯出正常運作

#### Scenario: Test corrupted database recovery
- **WHEN** 執行資料庫損壞測試
- **THEN** 模擬資料庫檔案損壞
- **AND** 驗證系統偵測損壞
- **AND** 驗證提供重建選項

#### Scenario: Test timezone edge cases
- **WHEN** 執行時區測試
- **THEN** 測試月份邊界日期（月底 23:59 → 隔月 00:00）
- **AND** 驗證支出歸類至正確月份
- **AND** 驗證跨時區顯示正確

### Requirement: Test Coverage Standards
系統 SHALL 維持最低測試覆蓋率標準。

#### Scenario: Minimum test count
- **WHEN** 執行測試套件
- **THEN** 測試數量不少於 700 個
- **AND** 所有測試通過
- **AND** 無跳過的測試（除非有文件說明原因）

#### Scenario: Critical path coverage
- **WHEN** 檢視測試覆蓋
- **THEN** 所有 Repository 有單元測試
- **AND** 所有 Service 有單元測試
- **AND** 所有 Screen 有 widget 測試
- **AND** 關鍵流程有整合測試

#### Scenario: New code test requirement
- **WHEN** 新增功能或修復 bug
- **THEN** 必須包含對應測試
- **AND** 測試驗證新行為
- **AND** 測試覆蓋失敗情境
