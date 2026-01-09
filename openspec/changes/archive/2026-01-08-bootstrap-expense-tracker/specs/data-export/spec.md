# Data Export

月份報銷單匯出功能。

## ADDED Requirements

### Requirement: Excel Export
系統 SHALL 將月份支出匯出為 Excel 格式。

#### Scenario: Export month to Excel
- **GIVEN** 2025年1月有 15 筆支出
- **WHEN** 使用者選擇匯出該月
- **THEN** 系統生成 Excel 檔案
- **AND** 檔名格式為 `報銷單_2025年01月_{用戶名}.xlsx`
- **AND** 包含所有未刪除的支出記錄

#### Scenario: Excel column structure
- **WHEN** 系統生成 Excel 檔案
- **THEN** 包含以下欄位：編號、日期、描述、原幣、金額、匯率、港幣金額、備註
- **AND** 第一列為標題列
- **AND** 最後一列為總計列

#### Scenario: Rate source annotation
- **GIVEN** 支出使用非自動匯率
- **WHEN** 系統生成 Excel
- **THEN** 備註欄顯示匯率來源（手動匯率/離線匯率/預設匯率）

### Requirement: ZIP Export with Receipts
系統 SHALL 將 Excel 及收據圖片打包為 ZIP。

#### Scenario: Create ZIP package
- **GIVEN** 月份有 Excel 和收據圖片
- **WHEN** 使用者選擇完整匯出
- **THEN** 系統生成 ZIP 檔案
- **AND** 檔名格式為 `報銷單_2025年01月_{用戶名}.zip`

#### Scenario: ZIP structure
- **WHEN** 系統生成 ZIP
- **THEN** 包含以下結構：
  - `報銷單_2025年01月/報銷單_2025年01月_{用戶名}.xlsx`
  - `報銷單_2025年01月/收據/001_20250103_描述.jpg`
  - `報銷單_2025年01月/收據/002_20250102_描述.jpg`
- **AND** 收據按編號排序命名

#### Scenario: Handle missing images
- **GIVEN** 部分收據圖片檔案遺失
- **WHEN** 系統生成 ZIP
- **THEN** 跳過遺失的圖片（不報錯）
- **AND** 繼續打包其他檔案

### Requirement: Share Export
系統 SHALL 允許使用者透過系統分享功能傳送匯出檔案。

#### Scenario: Share via system share sheet
- **GIVEN** 匯出檔案已生成
- **WHEN** 使用者點擊分享按鈕
- **THEN** 系統顯示 Android 分享選單
- **AND** 可選擇 Email、WhatsApp、雲端硬碟等

### Requirement: Export Preview
系統 SHALL 在匯出前顯示預覽資訊。

#### Scenario: Show export preview
- **WHEN** 使用者進入匯出頁面
- **THEN** 顯示將匯出的月份
- **AND** 顯示總筆數
- **AND** 顯示港幣總金額
- **AND** 提供「僅 Excel」和「Excel + 收據」選項

### Requirement: Export Error Handling
系統 SHALL 優雅處理匯出失敗情況。

#### Scenario: Export failure
- **WHEN** 匯出過程發生錯誤（如儲存空間不足）
- **THEN** 系統返回 `ExportException` 錯誤
- **AND** 顯示使用者友善錯誤訊息
- **AND** 清理任何部分生成的檔案

### Requirement: Empty Month Handling
系統 SHALL 處理無支出月份的匯出請求。

#### Scenario: Prevent empty export
- **GIVEN** 選定月份無任何支出記錄
- **WHEN** 使用者進入匯出頁面
- **THEN** 系統顯示「本月無支出記錄」
- **AND** 匯出按鈕置灰不可用

### Requirement: Export Temp File Cleanup
系統 SHALL 清理匯出產生的暫存檔案。

#### Scenario: Cleanup after share
- **GIVEN** 使用者完成分享操作
- **WHEN** 分享 sheet 關閉
- **THEN** 系統刪除暫存的 Excel/ZIP 檔案
- **AND** 釋放儲存空間

#### Scenario: Cleanup on export cancel
- **GIVEN** 匯出過程進行中
- **WHEN** 使用者取消匯出
- **THEN** 系統停止匯出作業
- **AND** 刪除已產生的部分檔案

### Requirement: Export Progress
系統 SHALL 顯示匯出進度。

#### Scenario: Show export progress
- **GIVEN** 月份有大量支出記錄
- **WHEN** 使用者執行完整匯出
- **THEN** 系統顯示進度指示器
- **AND** 顯示「正在打包收據 (15/30)」
- **AND** 完成後自動開啟分享選單

### Requirement: Long Description Handling
系統 SHALL 處理過長描述在 Excel 中的顯示。

#### Scenario: Truncate long description in Excel
- **GIVEN** 支出描述超過 100 字元
- **WHEN** 系統生成 Excel
- **THEN** 描述欄顯示前 100 字元 + "..."
- **AND** 完整描述放入備註欄
