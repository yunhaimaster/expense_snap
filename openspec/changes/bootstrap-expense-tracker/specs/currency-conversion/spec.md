# Currency Conversion

多幣種匯率轉換功能。

## ADDED Requirements

### Requirement: Supported Currencies
系統 SHALL 支援 HKD、CNY、USD 三種貨幣。

#### Scenario: Currency selection
- **WHEN** 使用者新增支出
- **THEN** 可從下拉選單選擇 HKD、CNY 或 USD
- **AND** 顯示對應貨幣符號（$、¥、US$）

### Requirement: Auto Exchange Rate Fetch
系統 SHALL 自動從 API 取得最新匯率。

#### Scenario: Fetch rate online
- **GIVEN** 設備有網絡連線
- **WHEN** 使用者選擇非 HKD 幣種
- **THEN** 系統從 currency-api 取得匯率
- **AND** 標記匯率來源為 `auto`
- **AND** 快取匯率至本地資料庫

#### Scenario: Primary API failure with fallback
- **GIVEN** 主要 API (jsdelivr.net) 失敗
- **WHEN** 系統嘗試取得匯率
- **THEN** 自動切換至備用 API (currency-api.pages.dev)
- **AND** 若成功則正常處理

### Requirement: Exchange Rate Caching
系統 SHALL 快取匯率資料，有效期 24 小時。

#### Scenario: Use cached rate
- **GIVEN** 快取中有未過期的匯率（< 24 小時）
- **WHEN** 使用者選擇該幣種
- **THEN** 系統使用快取的匯率
- **AND** 不發送 API 請求

#### Scenario: Cache expired
- **GIVEN** 快取中的匯率已過期（≥ 24 小時）
- **WHEN** 使用者選擇該幣種且有網絡
- **THEN** 系統從 API 取得新匯率
- **AND** 更新快取

### Requirement: Offline Rate Fallback
系統 SHALL 在離線時提供匯率 fallback 機制。

#### Scenario: Use cached rate offline
- **GIVEN** 設備離線且快取中有匯率（已過期）
- **WHEN** 使用者選擇該幣種
- **THEN** 系統使用過期的快取匯率
- **AND** 標記匯率來源為 `offline`
- **AND** 顯示「離線匯率」提示

#### Scenario: Use default rate when no cache
- **GIVEN** 設備離線且無快取匯率
- **WHEN** 使用者選擇該幣種
- **THEN** 系統使用預設匯率（CNY: 1.08, USD: 7.80）
- **AND** 標記匯率來源為 `default`
- **AND** 顯示「預設匯率」警告

### Requirement: Manual Rate Override
系統 SHALL 允許使用者手動輸入匯率。

#### Scenario: Enter manual rate
- **WHEN** 使用者點擊匯率輸入欄位並修改
- **THEN** 系統使用使用者輸入的匯率
- **AND** 重新計算港幣金額
- **AND** 標記匯率來源為 `manual`

### Requirement: HKD Amount Calculation
系統 SHALL 根據匯率自動計算港幣金額。

#### Scenario: Calculate HKD amount
- **GIVEN** 原始金額為 100 USD，匯率為 7.80
- **WHEN** 系統計算港幣金額
- **THEN** 結果為 780.00 HKD

#### Scenario: HKD input no conversion
- **GIVEN** 使用者選擇 HKD 幣種
- **WHEN** 使用者輸入金額
- **THEN** 港幣金額等於原始金額
- **AND** 匯率固定為 1.0

### Requirement: Rate Refresh
系統 SHALL 允許使用者手動重新取得匯率。

#### Scenario: Refresh rate button
- **WHEN** 使用者點擊「重新取得」按鈕
- **THEN** 系統嘗試從 API 取得最新匯率
- **AND** 若成功則更新顯示
- **AND** 若失敗則顯示錯誤訊息

### Requirement: Rate Limiting
系統 SHALL 限制匯率 API 請求頻率。

#### Scenario: Debounce rapid refresh
- **GIVEN** 使用者剛點擊過「重新取得」
- **WHEN** 使用者在 30 秒內再次點擊
- **THEN** 系統顯示「請稍後再試」
- **AND** 不發送 API 請求

#### Scenario: Show cooldown timer
- **GIVEN** 重新取得按鈕正在冷卻中
- **WHEN** 使用者查看按鈕
- **THEN** 按鈕顯示剩餘冷卻秒數
- **AND** 冷卻結束後恢復可用

### Requirement: Exchange Rate Precision
系統 SHALL 使用高精度儲存和計算匯率。

#### Scenario: Store rate with precision
- **GIVEN** API 返回匯率 0.123456
- **WHEN** 系統儲存匯率
- **THEN** 以整數格式儲存（×10⁶ = 123456）
- **AND** 保留 6 位有效數字

#### Scenario: Calculate with precision
- **GIVEN** 金額 100.50，匯率 7.82345
- **WHEN** 系統計算港幣金額
- **THEN** 結果四捨五入至小數點後 2 位
- **AND** 顯示為 786.46 HKD

### Requirement: Exchange Rate Display
系統 SHALL 清晰顯示匯率來源和狀態。

#### Scenario: Show rate source indicator
- **WHEN** 使用者查看匯率欄位
- **THEN** 顯示匯率來源標籤
- **AND** `auto` 顯示 ✓ 圖示
- **AND** `offline` 顯示 ⚠️ 圖示
- **AND** `default` 顯示 ⚠️ 圖示並標紅
- **AND** `manual` 顯示 ✏️ 圖示

#### Scenario: Show rate fetch time
- **GIVEN** 匯率從快取載入
- **WHEN** 使用者查看匯率
- **THEN** 顯示「更新於 X 小時前」
