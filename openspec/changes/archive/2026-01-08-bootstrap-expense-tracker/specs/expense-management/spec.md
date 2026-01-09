# Expense Management

核心支出記錄管理功能。

## ADDED Requirements

### Requirement: Expense Creation
系統 SHALL 允許使用者新增支出記錄，包含日期、金額、幣種、匯率、描述及收據圖片。

#### Scenario: Create expense with auto exchange rate
- **GIVEN** 使用者已拍攝收據照片
- **WHEN** 使用者輸入金額 258.00、選擇 CNY、填寫描述「淘寶包裝物料」
- **THEN** 系統自動取得 CNY→HKD 匯率
- **AND** 計算並顯示港幣金額
- **AND** 儲存支出記錄至本地資料庫
- **AND** 儲存壓縮後的收據圖片

#### Scenario: Create expense with manual exchange rate
- **GIVEN** 使用者選擇手動輸入匯率
- **WHEN** 使用者輸入匯率 1.10
- **THEN** 系統使用該匯率計算港幣金額
- **AND** 標記匯率來源為 `manual`

### Requirement: Expense Listing
系統 SHALL 以月份為單位顯示支出列表，支援分頁載入。

#### Scenario: View current month expenses
- **WHEN** 使用者開啟主頁
- **THEN** 系統顯示當月所有未刪除的支出記錄
- **AND** 每筆記錄顯示縮圖、日期、描述、原始金額及港幣金額
- **AND** 列表按日期降序排列

#### Scenario: Navigate between months
- **WHEN** 使用者點擊上一個月按鈕
- **THEN** 系統載入並顯示上個月的支出記錄
- **AND** 更新月份標題顯示

#### Scenario: Pagination loading
- **GIVEN** 當月有超過 20 筆記錄
- **WHEN** 使用者滾動至列表底部
- **THEN** 系統載入下一頁 20 筆記錄
- **AND** 追加至現有列表

### Requirement: Expense Detail View
系統 SHALL 提供支出詳情頁面，顯示完整資訊及原圖。

#### Scenario: View expense detail
- **WHEN** 使用者點擊列表中的支出項目
- **THEN** 系統顯示詳情頁面
- **AND** 顯示原始尺寸收據圖片
- **AND** 顯示所有欄位資訊（日期、金額、匯率、匯率來源、描述）

### Requirement: Expense Update
系統 SHALL 允許使用者編輯已存在的支出記錄。

#### Scenario: Edit expense description
- **GIVEN** 使用者正在檢視支出詳情
- **WHEN** 使用者修改描述並儲存
- **THEN** 系統更新資料庫中的記錄
- **AND** 更新 `updated_at` 時間戳

### Requirement: Expense Soft Delete
系統 SHALL 實作軟刪除機制，保留 30 天後永久刪除。

#### Scenario: Soft delete expense
- **WHEN** 使用者刪除一筆支出
- **THEN** 系統將 `is_deleted` 標記為 true
- **AND** 該記錄不再顯示於列表
- **AND** 顯示 Undo 提示（限時）

#### Scenario: Restore deleted expense
- **GIVEN** 支出在 30 天內被軟刪除
- **WHEN** 使用者選擇復原
- **THEN** 系統將 `is_deleted` 標記為 false
- **AND** 記錄重新顯示於列表

#### Scenario: Permanent cleanup
- **GIVEN** 支出被軟刪除超過 30 天
- **WHEN** 系統執行清理作業
- **THEN** 永久刪除資料庫記錄
- **AND** 刪除對應的收據圖片檔案

### Requirement: Month Summary
系統 SHALL 顯示當月支出統計摘要。

#### Scenario: Display month summary
- **WHEN** 使用者檢視某月份
- **THEN** 系統顯示該月總筆數
- **AND** 顯示該月港幣總金額

### Requirement: Input Validation
系統 SHALL 驗證所有使用者輸入。

#### Scenario: Validate amount range
- **WHEN** 使用者輸入金額
- **THEN** 系統驗證金額介於 0.01 ~ 9,999,999.99
- **AND** 最多接受 2 位小數
- **AND** 不接受負數或零

#### Scenario: Validate description length
- **WHEN** 使用者輸入描述
- **THEN** 系統驗證描述長度為 1-500 字元
- **AND** 移除首尾空白

#### Scenario: Validate date not in future
- **WHEN** 使用者選擇日期
- **THEN** 系統驗證日期不晚於今日
- **AND** 不接受未來日期

#### Scenario: Show validation errors
- **GIVEN** 使用者輸入無效資料
- **WHEN** 使用者嘗試儲存
- **THEN** 系統顯示具體錯誤訊息
- **AND** 標記有問題的欄位
- **AND** 不關閉表單

### Requirement: Replace Receipt Image
系統 SHALL 允許使用者替換已儲存的收據圖片。

#### Scenario: Replace existing receipt
- **GIVEN** 支出已有收據圖片
- **WHEN** 使用者在編輯頁面點擊「更換圖片」
- **THEN** 系統開啟相機/相簿選擇器
- **AND** 新圖片取代舊圖片
- **AND** 刪除舊圖片檔案

### Requirement: Onboarding Flow
系統 SHALL 在首次使用時引導使用者設定。

#### Scenario: First launch onboarding
- **GIVEN** 使用者首次開啟 App
- **WHEN** App 啟動完成
- **THEN** 系統顯示歡迎頁面
- **AND** 要求輸入使用者名稱（用於匯出檔名）
- **AND** 儲存後進入主頁

#### Scenario: Skip sets default name
- **GIVEN** 使用者在歡迎頁面
- **WHEN** 使用者跳過設定
- **THEN** 系統使用預設名稱「員工」
- **AND** 進入主頁

### Requirement: Deleted Items Recovery
系統 SHALL 允許使用者查看和復原已刪除的支出。

#### Scenario: View deleted items
- **GIVEN** 有支出被軟刪除
- **WHEN** 使用者進入設定頁面點擊「已刪除項目」
- **THEN** 系統顯示所有軟刪除的支出
- **AND** 顯示刪除日期和剩餘天數

#### Scenario: Restore from deleted list
- **GIVEN** 使用者在已刪除項目頁面
- **WHEN** 使用者選擇復原某筆支出
- **THEN** 系統將該支出標記為未刪除
- **AND** 支出重新出現在主列表

#### Scenario: Permanently delete from list
- **GIVEN** 使用者在已刪除項目頁面
- **WHEN** 使用者選擇永久刪除
- **THEN** 系統顯示確認對話框
- **AND** 確認後永久刪除記錄和圖片
