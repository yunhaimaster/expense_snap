# expense-categories Specification

## Purpose
為支出記錄提供分類功能，讓使用者能將支出按類型歸類，便於統計和報銷。

## Requirements

### Requirement: Predefined Category List
系統 SHALL 提供 8 個預設分類，不支援自訂分類。

#### Scenario: Available categories
- **WHEN** 使用者查看分類選項
- **THEN** 系統顯示以下分類（使用 camelCase enum name 儲存）：
  - 餐飲 (meals)
  - 交通 (transport)
  - 住宿 (accommodation)
  - 辦公用品 (officeSupplies)
  - 通訊 (communication)
  - 娛樂 (entertainment)
  - 醫療 (medical)
  - 其他 (other)

### Requirement: Optional Category Selection
系統 SHALL 允許使用者選擇性地為支出指定分類。

#### Scenario: Create expense with category
- **GIVEN** 使用者正在新增支出
- **WHEN** 使用者選擇分類「餐飲」
- **THEN** 系統儲存支出記錄包含 category = 'meals'

#### Scenario: Create expense without category
- **GIVEN** 使用者正在新增支出
- **WHEN** 使用者不選擇任何分類
- **THEN** 系統儲存支出記錄包含 category = null
- **AND** 支出正常顯示於列表

#### Scenario: Edit expense category
- **GIVEN** 使用者正在編輯已有分類的支出
- **WHEN** 使用者更改分類為「交通」
- **THEN** 系統更新 category = 'transport'
- **AND** updated_at 時間戳更新

#### Scenario: Remove category from expense
- **GIVEN** 使用者正在編輯已有分類的支出
- **WHEN** 使用者點擊已選中的分類 chip（取消選取）
- **THEN** 系統更新 category = null
- **AND** 使用 copyWith(clearCategory: true) 清除分類

### Requirement: Category Suggestion from OCR
系統 SHALL 基於 OCR 提取的文字自動建議分類。

#### Scenario: Suggest meals category
- **GIVEN** OCR 提取描述包含「餐廳」或「cafe」或「麥當勞」
- **WHEN** 系統執行分類建議
- **THEN** `ReceiptParseResult.suggestedCategory` = `ExpenseCategory.meals`

#### Scenario: Suggest transport category
- **GIVEN** OCR 提取描述包含「的士」或「uber」或「港鐵」
- **WHEN** 系統執行分類建議
- **THEN** `ReceiptParseResult.suggestedCategory` = `ExpenseCategory.transport`

#### Scenario: Suggest accommodation category
- **GIVEN** OCR 提取描述包含「酒店」或「hotel」
- **WHEN** 系統執行分類建議
- **THEN** `ReceiptParseResult.suggestedCategory` = `ExpenseCategory.accommodation`

#### Scenario: No suggestion when no match
- **GIVEN** OCR 提取描述不包含任何分類關鍵字
- **WHEN** 系統執行分類建議
- **THEN** `ReceiptParseResult.suggestedCategory` = null
- **AND** 分類選擇器保持未選中狀態

#### Scenario: User can override suggestion
- **GIVEN** 系統建議分類為「餐飲」
- **WHEN** 使用者選擇「其他」
- **THEN** 系統使用使用者選擇的分類
- **AND** 忽略 OCR 建議

#### Scenario: Empty description returns no suggestion
- **GIVEN** OCR 未能提取任何描述文字
- **WHEN** 系統執行分類建議
- **THEN** `suggestedCategory` = null

#### Scenario: Case insensitive matching
- **GIVEN** OCR 提取描述包含「UBER」（大寫）
- **WHEN** 系統執行分類建議
- **THEN** 建議分類為「交通」
- **AND** 匹配不受大小寫影響

#### Scenario: Long keyword priority over short keyword
- **GIVEN** OCR 提取描述為「麥當勞停車場」
- **WHEN** 系統執行分類建議
- **THEN** 建議分類為「餐飲」（麥當勞優先於停車）
- **AND** 長關鍵字優先於短關鍵字

### Requirement: Category Display in List
系統 SHALL 在支出列表中顯示分類標籤。

#### Scenario: Display category badge
- **GIVEN** 支出有分類「交通」
- **WHEN** 系統顯示支出卡片
- **THEN** 顯示「交通」標籤（CategoryBadge widget）
- **AND** 標籤使用該分類對應的顏色（theme-aware）

#### Scenario: Hide badge for uncategorized
- **GIVEN** 支出沒有分類（category = null）
- **WHEN** 系統顯示支出卡片
- **THEN** 不顯示 CategoryBadge
- **AND** 其他資訊正常顯示

#### Scenario: Badge colors adapt to theme
- **GIVEN** 支出有分類「餐飲」
- **WHEN** 使用者切換至深色模式
- **THEN** CategoryBadge 使用深色模式顏色 (#81C784)
- **AND** 文字顏色確保對比度

### Requirement: Category Accessibility
系統 SHALL 提供完整的無障礙支援。

#### Scenario: CategoryPicker screen reader support
- **GIVEN** 使用者啟用螢幕閱讀器
- **WHEN** 焦點移至「餐飲」chip（已選取）
- **THEN** 螢幕閱讀器朗讀「餐飲分類，已選取」

#### Scenario: CategoryBadge screen reader support
- **GIVEN** 使用者啟用螢幕閱讀器
- **WHEN** 焦點移至 CategoryBadge
- **THEN** 螢幕閱讀器朗讀「分類：餐飲」

### Requirement: Category in Export
系統 SHALL 在匯出 Excel 中包含分類資訊及統計。

#### Scenario: Export with category column
- **WHEN** 系統生成 Excel 匯出
- **THEN** 包含「分類」欄位（在「描述」和「原幣」之間）
- **AND** 未分類支出的分類欄位顯示為空白

#### Scenario: Category subtotals in export
- **GIVEN** 月份有多筆不同分類的支出
- **WHEN** 系統生成 Excel 匯出
- **THEN** Excel 底部包含「分類統計」區塊
- **AND** 只列出有支出的分類（不列出 0 元分類）
- **AND** 按港幣小計金額降序排列
- **AND** 未分類支出歸入「未分類」行

#### Scenario: Export with all uncategorized
- **GIVEN** 月份所有支出都沒有分類
- **WHEN** 系統生成 Excel 匯出
- **THEN** 分類統計只顯示「未分類」一行
- **AND** 金額等於月份總計

#### Scenario: Export with single category
- **GIVEN** 月份所有支出都是「餐飲」分類
- **WHEN** 系統生成 Excel 匯出
- **THEN** 分類統計只顯示「餐飲」一行
- **AND** 金額等於月份總計

### Requirement: Category Data Persistence
系統 SHALL 確保分類資料在各種操作中保持一致。

#### Scenario: Category survives backup and restore
- **GIVEN** 支出有分類「交通」
- **WHEN** 使用者執行雲端備份後還原
- **THEN** 支出的分類仍為「交通」

#### Scenario: Category survives soft delete and restore
- **GIVEN** 支出有分類「餐飲」
- **WHEN** 使用者刪除支出後從回收站還原
- **THEN** 支出的分類仍為「餐飲」

#### Scenario: Unknown category falls back gracefully
- **GIVEN** 資料庫中有 category = 'unknown_value'（可能來自舊版本）
- **WHEN** 系統讀取該支出
- **THEN** category 解析為 `ExpenseCategory.other`
- **AND** 系統記錄警告日誌

### Requirement: Database Migration
系統 SHALL 安全地升級資料庫結構。

#### Scenario: Upgrade from v1 to v2
- **GIVEN** 使用者有 v1 資料庫（無 category 欄位）
- **WHEN** App 升級並啟動
- **THEN** 資料庫升級至 v2
- **AND** 新增 category TEXT 欄位（nullable）
- **AND** 現有支出的 category = null
- **AND** 新增 idx_expenses_category 索引

#### Scenario: Fresh install gets v2
- **GIVEN** 使用者首次安裝 App
- **WHEN** App 建立資料庫
- **THEN** 資料庫版本為 v2
- **AND** expenses 表包含 category 欄位

## MODIFIED Requirements

### Requirement: Expense Creation (expense-management)
系統 SHALL 允許使用者新增支出記錄，包含日期、金額、幣種、匯率、描述、**分類**及收據圖片。

#### Scenario: Create expense with category
- **GIVEN** 使用者已拍攝收據照片
- **WHEN** 使用者輸入金額、選擇幣種、填寫描述、**選擇分類「餐飲」**
- **THEN** 系統儲存支出記錄包含 category = 'meals'

### Requirement: Auto-fill Form on Image Capture (receipt-ocr)
系統 SHALL 在拍照後自動填充表單欄位，**包含建議分類**。

#### Scenario: Auto-fill with category suggestion
- **WHEN** 使用者拍攝收據並完成 OCR
- **AND** `ReceiptParseResult.suggestedCategory` 不為 null
- **THEN** 分類選擇器自動選中建議分類
- **AND** 使用者可修改選擇

### Requirement: Excel Export Column Structure (data-export)
系統 SHALL 在 Excel 中包含分類欄位。

#### Scenario: Excel column structure with category
- **WHEN** 系統生成 Excel 檔案
- **THEN** 包含以下欄位：編號、日期、描述、**分類**、原幣、金額、匯率、港幣金額、備註
