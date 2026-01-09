# offline-support Specification

## Purpose
TBD - created by archiving change bootstrap-expense-tracker. Update Purpose after archive.
## Requirements
### Requirement: Connectivity Detection
系統 SHALL 即時偵測網絡連線狀態。

#### Scenario: Detect online status
- **WHEN** 設備連接 WiFi 或行動網絡
- **THEN** 系統標記為 online 狀態

#### Scenario: Detect offline status
- **WHEN** 設備失去所有網絡連線
- **THEN** 系統標記為 offline 狀態
- **AND** 觸發 UI 更新

### Requirement: Offline Indicator
系統 SHALL 在離線時顯示明確提示。

#### Scenario: Show offline banner
- **GIVEN** 設備處於離線狀態
- **WHEN** 使用者使用 App
- **THEN** 主頁頂部顯示離線提示 banner
- **AND** banner 顯示「目前離線，部分功能受限」

#### Scenario: Hide banner when online
- **WHEN** 設備恢復網絡連線
- **THEN** 離線 banner 自動消失

### Requirement: Offline Core Functions
系統 SHALL 確保核心功能在離線時可用。

#### Scenario: Create expense offline
- **GIVEN** 設備離線
- **WHEN** 使用者新增支出
- **THEN** 支出成功儲存至本地資料庫
- **AND** 使用快取/預設匯率
- **AND** 正常顯示於列表

#### Scenario: View expenses offline
- **GIVEN** 設備離線
- **WHEN** 使用者瀏覽支出列表
- **THEN** 正常載入並顯示本地資料

#### Scenario: Delete expense offline
- **GIVEN** 設備離線
- **WHEN** 使用者刪除支出
- **THEN** 軟刪除正常執行

### Requirement: Offline Feature Degradation
系統 SHALL 在離線時優雅降級部分功能。

#### Scenario: Exchange rate degradation
- **GIVEN** 設備離線
- **WHEN** 使用者需要匯率
- **THEN** 使用快取或預設匯率
- **AND** 顯示匯率來源標記

#### Scenario: Backup unavailable offline
- **GIVEN** 設備離線
- **WHEN** 使用者嘗試備份/還原
- **THEN** 顯示「需要網絡連線」提示
- **AND** 按鈕置灰不可用

#### Scenario: Rate refresh unavailable offline
- **GIVEN** 設備離線
- **WHEN** 使用者點擊重新取得匯率
- **THEN** 顯示「無法連線，請稍後再試」
- **AND** 不發送網絡請求

### Requirement: Export Offline
系統 SHALL 允許離線匯出資料。

#### Scenario: Export works offline
- **GIVEN** 設備離線
- **WHEN** 使用者執行匯出
- **THEN** Excel 和 ZIP 生成正常運作
- **AND** 分享功能視目標 App 而定

### Requirement: Auto Rate Refresh
系統 SHALL 在網絡恢復時自動更新匯率。

#### Scenario: Refresh rates on reconnect
- **GIVEN** 設備從離線恢復連線
- **WHEN** 使用者正在新增支出頁面
- **THEN** 系統自動嘗試更新匯率
- **AND** 若成功則更新顯示的匯率
- **AND** 顯示「匯率已更新」提示

#### Scenario: No refresh if cache valid
- **GIVEN** 設備從離線恢復連線
- **WHEN** 快取匯率仍在 24 小時內
- **THEN** 系統不發送 API 請求
- **AND** 繼續使用快取匯率

### Requirement: Offline First Data Access
系統 SHALL 優先使用本地資料。

#### Scenario: Instant data loading
- **WHEN** 使用者開啟 App
- **THEN** 立即從 SQLite 載入資料
- **AND** 不等待網絡請求
- **AND** 背景靜默更新匯率（若過期）

### Requirement: Connectivity State Persistence
系統 SHALL 追蹤連線狀態變化。

#### Scenario: Track connectivity changes
- **WHEN** 網絡狀態改變
- **THEN** 系統更新內部連線狀態
- **AND** 通知所有監聽的 UI 元件
- **AND** 記錄狀態變化至日誌

#### Scenario: Handle unstable connection
- **GIVEN** 網絡連線不穩定（頻繁斷連）
- **WHEN** 系統偵測到連線
- **THEN** 等待 2 秒穩定後才視為「在線」
- **AND** 避免頻繁觸發 API 請求

